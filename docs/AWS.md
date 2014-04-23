# Deploying to Amazon AWS/EC2

***DISCLAIMER: We are still finalizing this document.  Also, we may revisit how Wirbelsturm deploys to AWS with***
***the intent to further simplify the setup.  As such please consider AWS support as experimental at this point.***

---

Table of Contents

* <a href="#before-we-start">Before we start</a>
* <a href="#one-time-setup-instructions">One-time AWS setup instructions</a>
    * <a href="#local-bootstrapping">Bootstrapping your local AWS development environment</a>
    * <a href="#aws-pre-configuration">AWS pre-configuration</a>
        * <a href="#aws-pre-configuration-step1">Step 1/4: Set up a hosted DNS (sub)domain in Amazon Route 53</a>
        * <a href="#aws-pre-configuration-step2">Step 2/4: Create two Amazon IAM users for Wirbelsturm</a>
        * <a href="#aws-pre-configuration-step3">Step 3/4: Create an EC2 key pair for Wirbelsturm</a>
        * <a href="#aws-pre-configuration-step4">Step 4/4: Create an AWS security group for Wirbelsturm EC2 instances</a>
        * <a href="#aws-pre-configuration-full-config">Full wirbelsturm.yaml configuration example for AWS</a>
    * <a href="#custom-ami-creation">Custom AMI creation</a>
* <a href="#deploy">Deploy to AWS/EC2</a>
* <a href="#faq">AWS FAQ</a>

---

<a name="before-we-start"></a>

# Before we start

The reason why deploying to Amazon AWS requires a few _one-time_ preparation steps is because Vagrant is not yet able
to manage networking settings on AWS.  In spite of these shortcomings we try our best to make your AWS experience with
with Wirbelsturm as simple, easy, and fun as possible.


<a name="one-time-setup-instructions"></a>

# One-time AWS setup instructions


<a name="local-bootstrapping"></a>

## Bootstrapping your local AWS development environment

First you must install a few AWS-related software prerequisites on your _host machine_, i.e. the machine on which you
run commands such as `vagrant up`.  In this section we describe how to do this for Mac OS X.


### EC2 CLI utilities

```bash
$ brew install ec2-ami-tools ec2-api-tools aws-iam-tools
```

Add lines similar to the following to `~/.bashrc` if they do not exist yet.

_Note: Newer versions of the EC2 CLI utilities may have different paths/settings.  Make sure you follow the_
_respective installation instructions correctly._

```bash
export JAVA_HOME=`/usr/libexec/java_home`
export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.6.12.0/libexec"
export EC2_AMITOOL_HOME="/usr/local/Cellar/ec2-ami-tools/1.4.0.9/libexec"
export AWS_IAM_HOME="/usr/local/opt/aws-iam-tools/libexec"
# AWS keypairs and credentials
export EC2_PRIVATE_KEY=/path/to/your.pem
export AWS_ACCESS_KEY=CHANGEME
export AWS_SECRET_KEY=CHANGEME
# Add CLI utilities to PATH
export PATH=$PATH:$EC2_HOME/bin:$EC2_AMITOOL_HOME/bin
```

Tip: If you have both JDK 6 and JDK 7 installed you can explicitly enable the use of JDK 6 (which is the default version
of JDK for Wirbelsturm) with:

```bash
export JAVA_HOME=`/usr/libexec/java_home -v 1.6`
```

And because you now have security credentials in `~/.bashrc` you should restrict the access permissions to it:

```bash
$ chmod 600 ~/.bashrc
```


### Test drive

In this example we will launch a `t1.micro` instance with the AMI `ami-fb8e9292`.

Note: Make sure you replace `YOURKEYPAIR` with the name of your actual key pair.

```bash
$ INSTANCE_ID=`ec2-run-instances --user-data-file cloud-config --key YOURKEYPAIR --instance-type t1.micro ami-fb8e9292 | grep "^INSTANCE" | awk '{ print $2 }'`
$ ec2-describe-instances  $INSTANCE_ID
$ ec2-get-console-output  $INSTANCE_ID
$ ec2-terminate-instances $INSTANCE_ID
```

If you need to specify a custom security group (e.g. `allow-ssh`), use the `--group` parameter:

```bash
# Same command as above, but additionally sets a custom security group
$ INSTANCE_ID=`ec2-run-instances --user-data-file cloud-config --key YOURKEYPAIR --instance-type t1.micro --group allow-ssh ami-fb8e9292 | grep "^INSTANCE" | awk '{ print $2 }'`
```

<a name="aws-pre-configuration"></a>

## AWS pre-configuration

The following steps must be performed only once.


<a name="aws-pre-configuration-step1"></a>

### Step 1/4: Set up a hosted DNS (sub)domain in Amazon Route 53

You need to create a designated DNS sub-domain for a domain that you control, which you then configure to be managed by
[Amazon Route 53](http://aws.amazon.com/route53/).  Wirbelsturm requires such a hosted Route 53 domain to make the EC2
machines successfully discover and talk to each over the network.  (The Route 53 step is only required because Vagrant
does not support DNS/network configuration on AWS yet.)  The EC2 instances run by Wirbelsturm will register their
hostname/IP addresses under this DNS sub-domain so they are able to communicate with each other over the network.

* Example: If you control the domain `yourdomain.com` you should configure your DNS settings at your favorite DNS
  registrar (the likes of Gandi, GoDaddy, 1&1) to have a dedicated sub-domain such as `wirbelsturm.yourdomain.com`.
  You will then delegate the management of this sub-domain to Amazon Route 53.

A good user guide to set up your sub-domain for management by Amazon Route 53 is
[Creating a Subdomain That Uses Route 53 without Migrating the Parent Domain](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html)
in the official AWS documentation.  A further reference is the blog post
[Route 53, bring back some DNS loving to EC2](http://www.practicalclouds.com/content/blog/1/dave-mccormick/2012-02-28/route53-bring-back-some-dns-lovin-ec2).

Once your sub-domain is configured for Route 53, update the `domain` setting in your `wirbelsturm.yaml`:

```yaml
###
### Excerpt of wirbelsturm.yaml.  Leading whitespace is important!
###

# When using Amazon AWS the domain should be your hosted Route 53 sub-domain.
domain: your-wirbelsturm-sub.domain.com
```


<a name="aws-pre-configuration-step2"></a>

### Step 2/4: Create two Amazon IAM users for Wirbelsturm

You must create two dedicated IAM users for Wirbelsturm, each of which will get restricted security permissions: a
"deploy" IAM user and an "in-instance" IAM user:

1. The "deploy" user is used by Wirbelsturm/Vagrant to start/stop EC2 instances.  The AWS credentials of this user
   need to be only on the host machine from which you are running Wirbelsturm, i.e. they will never be seen by the
   EC2 instances.
2. The credentials of the "in-instance" user will be _embedded_ in the running EC2 instances so that these machines
   actually have the security permissions to modify the DNS settings of `wirbelsturm.yourdomain.com` via Route 53.
   Right now an unfortunate security side effect of this approach is that everyone being able to log into an EC2
   instance will be able to see these user credentials.  For this reason we limit the ACLs of the "in-instance" IAM
   user to only be allowed to modify Route 53 (but e.g. the user is not allowed to manage EC2 instances or any other
   AWS service).

We provide a utility script [aws-setup-iam.sh](../aws/aws-setup-iam.sh) that will create these two IAM users for
you.  You only need to run the following commands:

    # Start point is the top-level Wirbelsturm directory, i.e. where `Vagrantfile` is.
    $ cd aws/
    $ ./aws-setup-iam.sh

The utility script will print the access/secret key pairs of the two users, which you should write down and then
add to the AWS section in your `wirbelsturm.yaml`:

```yaml
###
### Excerpt of wirbelsturm.yaml.  Leading whitespace is important!
###

aws:
  <SOME LINES REMOVED>
  deploy_user:
    aws_access_key: CHANGEME   # Example: ABCDEFGHIJ1234567890
    aws_secret_key: CHANGEME   # Example: abcdefghijklmnopqrstuvwxyz12345678901234
  in_instance_user:
    aws_access_key: CHANGEME   # Example: ZYXZYXZYXZ1234567890
    aws_secret_key: CHANGEME   # Example: zyxzyxzyxzyxzyxzyxzyxzyxzyx1234567890123
  <SOME LINES REMOVED>
```


<a name="aws-pre-configuration-step3"></a>

### Step 3/4: Create an EC2 key pair for Wirbelsturm

You must create an EC2 key pair for Wirbelsturm.  This key pair is used by Wirbelsturm itself, but it is also needed
so that you can e.g. ssh into the EC2 instances via manual commands such as `vagrant ssh <hostname>`, or when using
our [ansible](../ansible) wrapper script to interact with running instances through Ansible.

Here are the instructions to create such an EC2 key pair via the Amazon EC2 console:

* Open the [Amazon AWS Console](https://aws.amazon.com/console/).
* Go to _EC2 Console > Network & Security > Key Pairs_.
* Click on _Create Key Pair_.  Give the key a name of your choice, for example "wirbelsturm".
* Your browser should automatically begin downloading the newly created private key.  If you named the key
  "wirbelsturm" then the private key file will be named `wirbelsturm.pem`.

Save this `.pem` file in a secure location, e.g. `~/.ssh/wirbelsturm.pem`.  Make your to restrict access to this
file with `chmod 600 ~/.ssh/wirbelsturm.pem`.

Then you must update the settings `keypair_name` and `private_key_path` in the `aws` section of your `wirbelsturm.yaml`.
If you followed the example above, `keypair_name` must be set to `wirbelsturm` and `private_key_path` must be set to
`~/.ssh/wirbelsturm.pem`.

Example:

```yaml
###
### Excerpt of wirbelsturm.yaml.  Leading whitespace is important!
###

aws:
  <SOME LINES REMOVED>
  keypair_name: CHANGEME       # Example: wirbelsturm
  private_key_path: CHANGEME   # Example: ~/.ssh/wirbelsturm.pem
  <SOME LINES REMOVED>
```


<a name="aws-pre-configuration-step4"></a>

### Step 4/4: Create an AWS security group for Wirbelsturm EC2 instances

By default, Wirbelsturm assigns the security group `wirbelsturm` to every EC2 instance (see
[wirbelsturm.yaml.template](../wirbelsturm.yaml.template)).

We provide a utility script [aws-setup-security-group.sh](../aws/aws-setup-security-group.sh) that will create such a
security group for you (based on Wirbelsturm default configuration settings).  You only need to run the following
commands:

    # Start point is the top-level Wirbelsturm directory, i.e. where `Vagrantfile` is.
    $ cd aws/
    $ ./aws-setup-security-group.sh

The utility script will print the name of the security group, which you should write down and then add to the relevant
AWS sections in your `wirbelsturm.yaml`.  It is important to remember that you must add security groups to each
relevant node (machine type) that you have defined in `wirbelsturm.yaml`.  Lastly, you can also assign more than one
security group to a node.

Example:

```yaml
###
### Excerpt of wirbelsturm.yaml.  Leading whitespace is important!
###

nodes:
  zookeeper_server:
    count: 1
    <SOME LINES REMOVED>
    providers:
      aws:
        instance_type: t1.micro
        ami: ami-abc12345
        security_groups:
          - wirbelsturm         # <<<< You must add the security group to each relevant node.
  storm_master:
    count: 1
    <SOME LINES REMOVED>
    providers:
      aws:
        instance_type: t1.micro
        ami: ami-abc12345
        security_groups:
          - wirbelsturm         # <<<< You must add the security group to each relevant node.
```


<a name="aws-pre-configuration-full-config"></a>

### Full `wirbelsturm.yaml` configuration example for AWS


Here is the full `wirbelsturm.yaml` example configuration, using the AWS settings of the previous sections.

_Note: To improve readability we have removed the "virtualbox" provider settings.  Of course you do not have to do_
_this in your `wirbelsturm.yaml`._

```yaml
###
### Excerpt of wirbelsturm.yaml.  Leading whitespace is important!
###

domain: your-wirbelsturm-sub.domain.com
environment: default-environment
aws:
  local_user: ec2-user
  rclocal_url: https://s3.amazonaws.com/yum.miguno.com/bootstrap/aws/rc.local
  keypair_name: wirbelsturm
  private_key_path: ~/.ssh/wirbelsturm.pem
  deploy_user:
    aws_access_key: ABCDEFGHIJ1234567890
    aws_secret_key: abcdefghijklmnopqrstuvwxyz12345678901234
  in_instance_user:
    aws_access_key: ZYXZYXZYXZ1234567890
    aws_secret_key: zyxzyxzyxzyxzyxzyxzyxzyxzyx1234567890123

nodes:
  zookeeper_server:
    count: 1
    hostname_prefix: zookeeper
    ip_range_start: 10.0.0.240
    node_role: zookeeper_server
    providers:
      aws:
        instance_type: t1.micro
        ami: ami-abc12345
        security_groups:
          - wirbelsturm
  storm_master:
    count: 1
    hostname_prefix: nimbus
    ip_range_start: 10.0.0.250
    node_role: storm_master
    providers:
      aws:
        instance_type: t1.micro
        ami: ami-abc12345
        security_groups:
          - wirbelsturm
```

_Note: Security groups are specified by **name** in non-VPC environments (e.g. `my-custom-name`).  When using Amazon_
_VPC however you must specify the security groups by their **id** (e.g. `sg-123abc456`)._


<a name="custom-ami-creation"></a>

## Custom AMI creation

_The instructions below use the Amazon Linux 2014.03.1 AMI [ami-fb8e9292](http://aws.amazon.com/amazon-linux-ami/) as_
_the base image (PV EBS-Backed 64-bit, US East N. Virginia)._

This section describes how to create a custom AMI image for use with Wirbelsturm when deploying to Amazon AWS.

At this point creating a custom AMI is primarily required because of a known bug in Vagrant that causes sporadic
provisioning errors when Vagrant tries to rsync folders to the EC2 instance.  See
[Vagrant issue #72](https://github.com/mitchellh/vagrant-aws/issues/72) and
[Vagrant Rsync Error before provisioning](http://stackoverflow.com/questions/17413598/vagrant-rsync-error-before-provisioning)
for details.

_Note: Recent versions of Vagrant support the (unfortunately not yet documented) `config.ssh.pty` setting.  This_
_setting may solve the provisioning issue above.  However we have not yet tested/integrated this new feature in_
_Wirbelsturm._

Launch the stock image `ami-fb8e9292` that will we modify to come up with our final image.  Make sure you use the
correct settings for `--key` (cf. `keypair_name` in `wirbelsturm.yaml`) and `--group` (cf. the `security_groups`
entries in `wirbelsturm.yaml`).

    $ ec2-run-instances \
        --region us-east-1 \
        --key wirbelsturm \
        --instance-type t1.micro \
        --block-device-mapping '/dev/sda1=:40:true:io1:400' \
        --group wirbelsturm \
        ami-fb8e9292

The command above will print an output similar to the following:

    RESERVATION  r-acfa279b  047236524511  wirbelsturm
    INSTANCE     i-fd8b3dae  ami-fb8e9292  pending      wirbelsturm  0  t1.micro  [...]

Here the instance ID is the first field after `INSTANCE`, in this example it is `i-fd8b3dae`.

Find out the public hostname of the newly launched instance.

    $ ec2-describe-instances <instance-id>

Upload the code to modify the stock image according to our needs.

    # Run the following commands from the top-level Wirbelsturm directory, i.e. where Vagrantfile is.
    $ cd aws/
    $ scp -i ~/.ssh/wirbelsturm.pem aws-prepare-image.sh puppetlabs.repo ec2-user@<instance-hostname>:~
    $ ssh -i ~/.ssh/wirbelsturm.pem ec2-user@<instance-hostname>
    $ ./aws-prepare-image.sh

Optional but recommended: delete `~/.bash_history` to put the box in a clean state.  You may need to logout and log back
in and re-delete the history file "for real" (the latest "buffer" of commands is written to the history file after
logout).

Now save the image for later re-use.

    $ ec2-create-image \
        --name wirbelsturm-base-2014.03 \
        --description 'Stock ami-fb8e9292 (Amazon Linux 2014.03.1) with Puppet 3.5.x and fix for vagrant-aws issue #72' \
        --region us-east-1 \
        --hide-tags \
        <instance-id>
    IMAGE ami-abc12345   <<<< Make sure to write this down and use it in wirbelsturm.yaml

**Important Note: It may take a few minutes until the new image is available for use.**

Get information about the newly created image:

    $ ec2-describe-images <image-id>
    IMAGE ami-abc12345  047336254512/wirbelsturm-base 047336254512  available private   x86_64  machineaki-88aa75e1     ebs paravirtual xen
    BLOCKDEVICEMAPPING  EBS /dev/sda1   snap-d8c7978b 40  true  io1 400

In case you made a mistake you can delete your custom AMI and start from scratch:

    # WARNING: This command DELETES the custom AMI!
    $ ec2-deregister <image-id>

Lastly, terminate the running EC2 instance that you used for creating the custom AMI:

    $ ec2-terminate-instances <instance-id>


<a name="deploy"></a>

# Deploy to AWS/ECS2

_This section assumes you have succesfully completed the one-time AWS setup instructions above._

To deploy to AWS you only need to set the `--provider=aws` parameter:

    # Option 1: Sequential provisioning (native Vagrant)
    $ vagrant up --provider=aws

    # Option 2: Parallel provisioning (Wirbelsturm wrapper script for `vagrant`)
    #           Logs are stored under `provisioning-logs/`.
    $ ./deploy --provider=aws

**Important Note: It may take a few minutes after the deployment finishes before the machines can actually see each**
**other in DNS via Route 53.**

You only need to give the `--provider=...` parameter when launching new machines.  Any other commands such as
`vagrant status`, `vagrant ssh`, and `vagrant destroy` automatically now whether the target machines reside in AWS or
elsewhere.


<a name="faq"></a>

# AWS FAQ

## Cannot launch more than 50 instances?

By default Amazon AWS accounts have a **default limit of 50 EC2 instances** running at the same time.  If you need
more, you must [request Amazon to increase this limit](https://aws.amazon.com/contact-us/ec2-request/) for your
account.


## Strange error message when trying to `vagrant up` via AWS

You might be getting a "weird" error message when deploying to AWS, and the error message may not tell you any useful
information what actually caused the problem.  In that case you may want to apply the following patch, which
unfortunately is not yet merged into the official `vagrant-aws` plugin.

Patch `lib/vagrant-aws/action/run_instance.rb` under `~/.vagrant.d/gems/gems/vagrant-aws*/` according to
https://github.com/jeremyharris/vagrant-aws/commit/1473c3a45570fdebed2f2b28585244e53345eb1d
and https://github.com/mitchellh/vagrant-aws/issues/75.

This patch will cause `vagrant-aws` to print a more meaningful error message, which should help you to correctly
identify the actual problem.


## How to find my `aws.keypair_name` value for configuring Wirbelsturm/Vagrant for AWS?

`aws.keypair_name`:

* Go to https://console.aws.amazon.com/ec2/home?region=us-east-1#s=KeyPairs
* Find the name of your desired key pair in column _Key Pair Name_.


## Find the AMI id of a running VM in EC2?

The [AMI information is available within the VM](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonLinuxAMIBasics.html#IdentifyingLinuxAMI_Images)
in the files:

    /etc/image-id
    /etc/system-release

See also [Amazon Linux AMI IDs](http://aws.amazon.com/amazon-linux-ami/).


## Match EC2 instance type with compatible AMI images?

See [Amazon Linux AMI Instance Type Matrix](http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/).


# Appendix: Configuring s3cmd

_This section is only needed for Wirbelsturm developers (but not for mere users of Wirbelsturm)._

We manage our own public yum repository for RPMs required by Wirbelsturm.  This yum repository is hosted on S3.  This
section describes the base setup for managing this repository.


## Installing s3cmd

Install and configure `s3cmd`.

```bash
$ brew install s3cmd
$ s3cmd --configure
```

The following example uploads the local file `rc.local` to S3.  The access permissions are set so that everybody can
read and download the file from S3.

```bash
$ s3cmd put --acl-public rc.local s3://yum.miguno.com/bootstrap/aws/rc.local
```
