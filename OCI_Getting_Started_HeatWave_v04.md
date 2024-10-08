---
title: Getting Started with MySQL HeatWave for AWS on OCI
parent: [tutorials]
tags: [mysql, database, heatwave, oci, ]
categories: [cloudapps]
thumbnail: assets/a-mysqglhw-devrel0622-thmb001.png
date: 2022-10-08 17:00
description: "Getting your OCI tenancy ready to connect to MySQL HeatWave on AWS. We will create a compute instance, DB System, and endpoint. We also provision MySQL HeatWave on AWS."
author: Victor Agreda
mrm: WWMK220224P00058

---
MySQL HeatWave for AWS makes perfect sense if you need a massively parallel, high performance, in-memory query accelerator for the MySQL Database Service. Instead of crafting complicated ETL pipelines to move data around, HeatWave accelerates MySQL performance by orders of magnitude for combined analytics and transactional workloads (OLAP and OLTP). The MySQL Database Service is built on MySQL Enterprise Edition, which allows developers to quickly create and deploy secure cloud native applications using the world's most popular open source database.

Oracle designed this so developers can focus on the important things, like managing data, creating schemas, and providing highly-available applications. HeatWave can perform analytics in real time, and MySQL HeatWave for Amazon Web Services (AWS) is a fully managed service, developed and supported by the MySQL team in Oracle. Oracle automates tasks like backup, recovery, and database and operating system patching. "Worry less, crunch more," as we say!

One of the incredible things about Oracle MySQL HeatWave is the ability to [run analytics](https://www.oracle.com/mysql/heatwave/) directly against your existing transactional data, so there's no need to shuffle that data off to a separate system when you need to perform massively parallel analysis.

To get started, we'll create a VCN, Compute instance (to serve as our bastion host), and install MySQL so we can connect to HeatWave for analysis. Note that this is working within Oracle Cloud, but we’ll cover AWS setup in another tutorial to show you how you can leverage HeatWave in a multi-cloud scenario. What a time to be alive!

Let's look at how to get started. If you're already developing in Oracle Cloud (OCI), you'll find it's relatively easy to get going, as HeatWave on AWS is integrated with OCI's Identity and Access Management system. When you sign up for HeatWave on AWS, you'll be directed to the OCI login page where you must sign in with an OCI Cloud Account. After signing in, you'll be directed to the OCI Console to complete the MySQL HeatWave on AWS sign-up process. When signing into the HeatWave Console, you are directed to OCI for authentication and then back to the HeatWave Console. To keep things simple, billing is still managed and monitored in OCI.

Since we're just getting started, let's start at the beginning and create a Compute instance with the proper access rules and see how to create a HeatWave cluster in OCI. If you're already using AWS, we'll cover that in a separate tutorial.

## PREREQUISITES

- An OCI account and Oracle Cloud Account name
- Admin access
- A compatible browser (Chrome 69+, Safari 12.1+, or Firefox 62+ or any browser that is Oracle Jet-approved)

## OVERVIEW

MySQL HeatWave on AWS uses predefined Oracle Identity Cloud Service (IDCS) groups and policies to control user access (and the type of access) to MySQL HeatWave on AWS. This is a little different than HeatWave on Oracle Analytics Cloud (which has its own interface and services). You should have the ability to create and modify policies, users, and the like. Also, we are assuming you're creating the database and administering it, or at least getting the prep work done. Look at you, a one-stop shop!

1.  Create a Compartment
2.  Create a a VCN and configure for database access
3.  Create users and groups (if you haven't already)
4.  Create a Bastion Host Compute instance
5.  Connect and Install MySQL Shell
6.  Create a MySQL database
7.  Create a DB System with HeatWave-compatible shape
8.  Activate HeatWave on AWS

Wondering why this is a "bastion host"? You can [read more about bastions here](https://www.oracle.com/security/cloud-security/bastion/).

NOTE: Once you’re connecting databases and analytics, there’s a better production method for connecting, and that’s creating a Private Access Channel (OAC), which you can [learn all about here](https://blogs.oracle.com/analytics/post/how-to-create-oac-instances-on-oci-native-using-multiple-stripes-or-instances-of-idcs).

In our example, we’re using a quick and dirty approach to set things up to use HeatWave. 

Let’s get started with the basics! We begin by slicing off a piece of the cloud as our own little homestead. There are a couple of ways to do this, but one of the simplest is to create a Compartment (you could also start with a Compute instance). This is a “place for your stuff” within your tenancy and is quite flexible. As you might imagine, we need to create a group of users who can administer our system, and Identity and Access Management (IAM) is where you’ll go to configure this for any compartments you create.

1. **Create a Compartment**

	{% imgx assets/create-compartment-hwaws-devrel0266va.png %}

	Menu: Home > Identity & Security > Compartments

	I could have set all of this up in my root compartment, but a new compartment is a better way to organize things.

	Creating compartments simple, and a necessary starting point to organize and configure your work. I've named mine something clever, like `my_heatwave_testing` so I know what it's for.

2. **Create a a VCN and configure for database access**

	Menu: Home > Networking > Virtual Cloud Networks

	Create a VCN and subnets using _Virtual Cloud Networks > Start VCN Wizard > Create a VCN with Internet Connectivity_. Of course you'll get a private subnet as well.

	{% imgx assets/start_a_vcn_wizard-devrel0622va.png %}

	The handy wizard will walk you through creating a network interface for your system, although there are lots of ways to configure this, let’s not get distracted. Notice that I chose the compartment I set up earlier, `my_heatwave_testing` -- because that's important!

	{% imgx assets/vcn_config_screen2-devrel0622va.png %}

	Now let's configure the VCN's security list to allow traffic through MySQL Database Service ports. Click on the Private Subnet for the VCN you created, and click the _Security List_ for it.

	{% imgx assets/vcn_edit_subnet_s1-devrel0622va.png %}

	Now click _Add Security list_.

	We'll add some ingress rules needed to enable the right ports, 3306 and 33060. Here are the details:

	```
	Source CIDR: 0.0.0.0/0

	Destination Port Range: 3306,33060

	Description: MySQL Port
	```

	And click _Add Ingress Rules_.

	{% imgx assets/vcn_ingress_rules_example-devrel0622va.png %}

	Looking good so far!

3. **Create users and groups (if you haven't already)**

	We’ll need to set permissions and limit access somewhat, even in our “quick and dirty” example, but you can [read all about managing groups here](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managinggroups.htm). Typically we'd create a group, create policies, and then add users to the group.

	Let’s make friends with the Identity and Security options.

	Create a group for your users; in my example I’ve created a group called `database_user` (just to be confusing, as I should have named it `database_admins`, but this was just a clever ploy to keep you on your toes).

	Add users to the group. In our example, we’ll add ourselves to this group that will administer our compute instance running MySQL-shell. 

	Of course, for a group you’ll first create all the users you need, add those into the group needing access at the levels you determine, and rest assured that you can set them loose with appropriate access controls.

	We allow access by setting policies, allowing one group to have full access (admins), and give other groups limited access (database users, for example).

	For MySQL HeatWave on AWS, there are some specific policy statements we can use, detailed in the charts below.

	{% imgx assets/hw_policy_aws_statements-devrel0622va.png %}

	This is just making it possible to configure and administrate our compartment, and define the scope of the access applied to the database instance.

	For more on adding users and setting policies in OCI, refer to [this documentation](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/addingusers.htm#Add).

4. **Create a Bastion Host Compute Instance**

	MENU: Main > Compute > Instances

	Be sure to select the compartment you set up earlier, under _List Scope_.

	{% imgx assets/compute_hw_listscope_compartment-devrel0622va.png %}

	{% imgx assets/create_instance_hw_devrel_0522-0622va.png %}

	Click _Create Instance_ (easy, right?)

	Name it something useful, and right now we'll leave the Availability Domain, Fault Domain, Image, and Shape as-is. You can use a free-tier Compute!

	We’re going to use Oracle Linux, but one of the niceties here are the choices of Compute shapes and Linux distributions to choose from. There’s even a developer distro, which comes pre-configured with key frameworks. For our purposes, we’ll want to make sure it’s set up to work with HeatWave. Plus, we'll use a Bastion Host for better security. Bastions provide "restricted and time-limited access to target resources that don't have public endpoints," and you can [read all about them here](https://docs.oracle.com/en-us/iaas/Content/Bastion/Concepts/bastionoverview.htm).

	{% imgx assets/create_compute_hw_devrel0522aa.png %}

	If you want to know more, [here's a tutorial on launching a Linux instance](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/launchinginstance.htm), but I'll walk you through the basics now. Bear in mind that our compute instance can be pretty minimal, and there are free tier shapes that could work ([our always-free tier VM](https://www.oracle.com/cloud/free/) is quite generous).

	{% imgx assets/compute_network_hw_devrel0522aa.png %}

	Scrolling down, you'll see the Networking section, where you want to make sure to use the VCN you created previously, as well as make sure you're in the proper compartment. 

	And, of course, during this process you’ll generate SSH keys so you can access your computer instance remotely. You can do this within the Cloud Shell in OCI’s dashboard, or the SSH client of your choice.

	More: [Install Node Express on an Oracle Linux Instance](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/node-on-ol/01oci-ol-node-summary.htm#install-node-ol).

	And here's [a video on working with SSH keys](https://www.youtube.com/watch?v=LMvYOSkXF1k).

	Also, the path of least resistance for creating a key pair will be letting Oracle generate one. The key pair will allow you to log in remotely and install MySQL-shell, etc. 

	**NOTE:** In many labs we’ll have you use the Cloud Shell, which is a convenient command line interface available directly in the OCI dashboard. I’m old school, so I’m just using Terminal on my Mac. You can use the SSH client of your choice, of course!

	Of course, you'll need the public IP for your compute instance, which is found in Compute > Instances > Instance details. Under "Instance Access" you'll find the public IP and username (opc) you'll need to connect, with a handy "copy" button.

	{% imgx assets/heres-public-ip-hw-oci-fy23-devrel.png %}

	Now we'll be able to [connect via SSH or the Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/accessinginstance.htm), and since you have a public IP, you can just ssh into your compartment and the OCI Linux Compute instance. As always, keep the private key in a safe place, and `chmod 400` the private key to keep it from being modified (and throwing a warning).

	Go ahead and click Create. 

	It'll take a moment for the provisioning to finish up, but when it's done the large square icon will turn green, meaning all systems are GO!

5. **Connect and install MySQL Shell**

	To connect, let's use the handy Cloud Shell. It's a little Linux terminal embedded in the OCI dashboard (and it's adorable). In the upper right corner, click the Cloud Shell prompt icon and a command line will open at the bottom of the browser.

	{% imgx assets/cloudshelliconhwtesting-devrel0622va.png %}

	Drag and drop the previously saved private key into the cloud shell, uploading it to your home directory.

	{% imgx assets/cloudshelluploadprivkey_hwdevrel-devrel0622va.png %}


	Under Instance Access, you'll see the public IP address, and the handy *Copy* button. Copy the public IP.

	Now let's ssh in, first protecting the private key file.

	```console
	chmod 400 <private-key-filename>.key
	```

	Then use your public IP address and username opc:

	```console
	ssh -i <private-key-file-name>.key opc@<compute_instance_public_ip>
	```

	If asked to accept the fingerprint, type *yes* and hit enter, and you've been added to the list of known hosts, congrats. We're in! If you see Tron, wave.

	Now we install MySQL Shell; pretty easy these days. In my case, I used SSH to log into my compute instance (don’t forget you’ll need your private key) and used `yum` to install what I needed.

	You can first install MySQL on compute with:

		sudo yum install mysql

	Then install the MySQL Client on the compute instance using the command:

		sudo yum install mysql-shell`

	Once we create our HeatWave-compatible DB System, we'll connect to to it using the MySQL Client:

		mysqlsh --host <DBSystemEndpointIPAddress> -u <Username> -p

	You can [learn more about MySQL Shell here](https://dev.mysql.com/doc/mysql-shell/8.0/en/).

	More on [connecting database systems here](https://docs.oracle.com/en-us/iaas/mysql-database/doc/connecting-db-system.html#GUID-70023ABD-5418-4C1F-975F-F3E2ABC0F93E). 

6. **Create a DB System**

	Remember a little while ago when we mentioned the endpoint for your DB System? Let's set that up now.

	Menu > Databases > DB Systems

	{% imgx assets/createdbsys_warn_devrel_0522va.png %}

	Notice that the system warns you if you haven't already set up users, a VCN, and so on. That's nice. Don't forget to check which compartment you'll create this in, again under List Scope on the left. Click _Create DB System_.

	Double-check the compartment, give it a name, and select _HeatWave_ (of course).

	You'll create admin credentials, be sure to save those somewhere handy but safe.

	In Configure Networking, you'll use the compute instance created earlier, but we'll use the private subnet. Leave the default domain and go to _Configure Hardware_.

	Confirm that in the Configure Hardware section, the selected shape is MySQL.HeatWave.VM.Standard.E3.

	Also:

	- CPU Core Count: 16,
	- Memory Size: 512 GB, 
	- Data Storage Size: 1024

	In the Configure Backup section you may leave the default backup window of 7 days.

	Keep scrolling and click _Show Advanced Options_.

	Go to the Networking tab, in the Hostname field enter the exact name of your DB System.

	Make sure port configuration corresponds to the following:

	- MySQL Port: 3306
	- MySQL X Protocol Port: 33060

	And... click _Create_!

	This time a yellow hexagon will appear, and eventually it'll turn green and your DB System will be up and running. Make some tea or grab some water, you've done a lot.

7. **Create a MySQL database**

	Now, you'll want to create your database and import any data you need. HeatWave is really designed for big data sets, needing fast analysis, so even though I’m importing the tiniest database ever, you can load up as much as you like (provided you have the storage for it). Plus, queries can be run in the cluster without offloading to a separate database. Whether you're deploying to OCI or AWS, we got you.

	Finally, the fun part! Import a .sql file. [Here's a video on importing using the command line](https://www.youtube.com/watch?v=gvcBDA2wJJ4).

	The key steps are:

	1. Type: `mysql -u username -p database_name < file.sql`.
		- The username refers to your MySQL username
		- database_name refers to the database you want to import
		- `file.sql` is your filename
	2. If you've assigned a password, type it now and press Enter.

	Lots of fans of `mysqldump` out there, so here’s how that works (using a made-up database for magazines):

	1. To import a .sql file with `mysqldump`, use the `mysqlimport` command and use the following flags and syntax

			$ mysqlimport -u magazine_admin -p magazines_production ~/backup/database/magazines.sql
	2. `-u` and `-p` are needed for authentication, and are then followed by the name of the database you want to import into.
	3. You'll need to specify the path to your SQL dump file that will contain your import data: `~/backup/database/magazines.sql`
	4. You won't need to use `>` or `<` for importing, but you will need them for exporting in the next guide.
	5. This will prompt a password request.
	6. Your file will be automatically imported. 

	Now that we have some data, we probably want to _do_ stuff with it, including visualize it in various ways. Let's add some analytics to accomplish this -- and continue our journey to the really big show, HeatWave. This is where things get really interesting, and you can see how Oracle has created a vast array of options for your data needs.

	The key is that you have a database running on OCI, and that database now has an endpoint which we can connect to HeatWave for analytics. 

8. **Activate HeatWave on AWS**

	Remember the DB System we just created? Now we can activate MySQL HeatWave in AWS and connect our DB System to a HeatWave Cluster to run queries on!

	{% imgx assets/hw-entercloudname-screen-devrel0922.png %}

	You'll go to [cloud.mysql.com](https://cloud.mysql.com/), where you'll see the welcome page. Enter your Oracle Cloud Account name and click _Continue_.

	Click _Enable MySQL HeatWave on AWS_. This takes you to a Admin page where you will go through a brief setup process. You may have to upgrade your account to paid with a credit card, and once complete, you'll go to the OCI Console. Try not to time this for the last minute, as provisioning may take a moment.

	From the OCI Console navigation menu, select _Databases_.

	MySQL HeatWave on AWS appears on the Home tab under the Featured label.

	Under MySQL HeatWave on AWS, click _Administration_, and you'll go back to the setup.

	Now click _Provision_ to (of course) provision MySQL on AWS. After the provisioning operation is completed, a message appears stating that MySQL HeatWave on AWS is ready and you are presented with options to open the MySQL HeatWave console, set up users, and view billing information.

### Summary - So far!

What we've done so far, all on OCI, is set up a Virtual Cloud Network with ports for MySQL use, created a Bastion Compute instance, then set up a MySQL database, and now we have an endpoint for our HeatWave on AWS instance, and HeatWave should be provisioned on AWS.

Want to know more? Join the discussion in our [public Slack channel](https://bit.ly/odevrel_slack)!




