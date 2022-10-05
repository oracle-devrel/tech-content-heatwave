---
title: Getting Started with MySQL HeatWave for AWS on AWS
parent: [tutorials]
tags: [mysql,database,heatwave,aws]
categories: [cloudapps]
thumbnail: assets/a-mysqglhw-devrel0622-thmb001.png
date: 2022-10-08 17:00
description: Setting up on AWS to connect to MySQL HeatWave on AWS. We'll create a database and endpoint. We also provision MySQL HeatWave on AWS.
author: Victor Agreda
mrm: WWMK220224P00058

---
If you're developing database applications on AWS and need a massively parallel, high performance, in-memory query accelerator for the MySQL Database Service, that's what MySQL HeatWave on AWS was built to do. Instead of crafting complicated ETL pipelines to move data around, HeatWave accelerates MySQL performance by orders of magnitude for combined analytics and transactional workloads (OLAP and OLTP). The MySQL Database Service is built on MySQL Enterprise Edition, which allows developers to quickly create and deploy secure cloud native applications using the world's most popular open source database. 

HeatWave can perform analytics in real time, and MySQL HeatWave for Amazon Web Services (AWS) is a fully managed service, developed and supported by the MySQL team in Oracle. 

One of the best things about Oracle MySQL HeatWave is the ability to [run analytics](https://www.oracle.com/mysql/heatwave/) directly against your existing transactional data, so there's no need to shuffle that data off to a separate system when you need to perform massively parallel analysis.

To get started, let's set up a MySQL database on AWS so we can connect to HeatWave for analysis. 

{% imgx assets/aws-creatingdb-devrel0922.png %}

Note that HeatWave on AWS is integrated with OCI's Identity and Access Management system. When you sign up for HeatWave on AWS, you'll be directed to the OCI login page where you must sign in with an OCI Cloud Account. After signing in, you'll be directed to the OCI Console to complete the MySQL HeatWave on AWS sign-up process. When signing into the HeatWave Console, you are directed to OCI for authentication and then back to the HeatWave Console. To keep things simple, billing is still managed and monitored in OCI.

Since it's a multi-cloud world, in this article we're creating an AWS database we can connect to MySQL HeatWave on AWS.

## PREREQUISITES

- An Oracle Cloud Account name
- An AWS account and root user credentials
- A compatible browser (Chrome 69+, Safari 12.1+, or Firefox 62+ or any browser that is Oracle Jet-approved)

## OVERVIEW

We are assuming you're creating the database and administering it, or at least getting the prep work done. Or maybe you've already set something up in AWS -- either way, this is a quick-and-dirty overview of getting started.

1.  IAM User Keys
2.  Create a VPC
3. 	Create a database instance
4.  Connect to database
5.  Activate HeatWave on AWS

In our example, we’re using a quick and dirty approach to set things up to use HeatWave. 

Basically we'll lean on the "easy mode" in AWS to create a Compute instance, network access, and database. Once we have the endpoint for our database we can activate MySQL HeatWave on AWS which we can use to run analytics. Easy!

1. **Identity Access Management on AWS**

	If you've set up your own AWS account, you've already got admin access. Of course, for best practices we wouldn't want to do everything as root, so here we should go to _Users_ and choose _Add Users_. Go ahead and create an Administrator account and check the box next to _AWS Management Console access_. Use a custom password.

	Choose _Next: Permissions_. In Set permissions select _Add user to group_. You'll then _Create group_, and for the name let's be descriptive and call it Administrators.

	Select filter policies and then AWS managed - job function. In that policy list, check _Administrator Access_. Now you can _Create group_!

	You may need to refresh the page, but select this new group and choose _Next: Tags_. You can now add tags in much the same way as in OCI, helping you organize and manage projects.

	Using _Next: Review_ you can see the groups to be added for this new user -- so you're basically done and can click _Create User_.

	AWS uses access keys similar to OCI when signing in with keys. To get the keys for this new user, go to the IAM console > Users > and choose the name of the new user. Choose the _Security credentials_ tab. In the Access keys section, select _Create access key_.

	Just like on OCI, you won't get another chance to grab the secret key, so select _Show_. You can now download the .csv file and close the dialog box. You're all set to use the key pair.

2. **Create a a VPC and configure for database access**

	Now that we've created an admin, let's create a security group and some network access. You can read all about [creating a new VPC here](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/gsg_create_vpc.html).

	Much like OCI, this tool allows us to create and configure network access with full firewall controls so we can open up an endpoint for our database. But we'll also need to set up some security controls.

	Head to the VPC console at [console.aws.amazon.com/vpc](https://console.aws.amazon.com/vpc).

	In the upper-right corner you'll choose the region. MySQL HeatWave on AWS supports all availability zones within supported AWS regions, with the exception of those that do not support the Amazon EC2 instance types used by MySQL HeatWave on AWS.

	The AWS regions where MySQL HeatWave on AWS is available include: US East (Northern Virginia) Region (us-east-1).

	Now, in Navigation, choose _Security Groups_. Choose _Create..._ and add the basic details as you see fit. Choose the VPC you want to create your database in.

	For Inbound rules, choose _Add rule_, and for Type choose _Custom TCP_. Next is Port range, so enter the port value to use for your DB instance, and for Source, choose a security group name or type the IP address range (CIDR value) from where you access the DB instance. Choosing _My IP_, will allow access to the DB instance from the IP address detected in your browser.

	If you need to add more IP addresses or different port ranges, choose _Add rule_ and enter the information for the rule. In our case, we want to add some ingress rules needed to enable the right ports, 3306 and 33060. Here are the details:

	```
	Source CIDR: 0.0.0.0/0

	Destination Port Range: 3306,33060

	Description: MySQL Port
	```

	(Optional) In Outbound rules, add rules for outbound traffic. By default, all outbound traffic is allowed. 

	Choose _Create security group_.

	Looking good so far!


3. **Create a MySQL database instance**

	In point of fact, you can create a VPC along with an EC2 instance and have connectivity along with a database [in a few simple steps](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.SQLServer.html). Not only that, it'll be a MySQL database. The sticking point is that the VPC you create won't be configured to allow incoming external traffic. Thus, if you go the "easy" route, you'll need to edit the access list on the VPC it creates. That's not difficult, just be aware of the extra steps.

	{% imgx assets/aws-dbchoices-panel-devrel0922.png %}

	Instead, we'll leap straight into a MySQL database instance. Go to the RDS console, and choose the region you used above. Click _Create Database_ and choose _Standard Create_. Choose MySQL (that seems obvious).

	Configure the database ID and credentials -- you know how important these will be, as we'll use them to wire up our HeatWave cluster to the database.

	In Additional conncectivity configurations, set Public Accessible to yes and the VPC security group will need to open Database port 3306.

	We'll set the authentication to password auth, and enter a name for the initial database. The rest is largely set, so we can create our datbase now.

	Don't forget that in our security group rules we should set CIDR inbound and outbound rules to 0.0.0.0/0.

	It may take several minutes for this to finish setting up. Below is one example of a database configuration.

	{% imgx assets/aws-hw-db-config-devrel0922.png %}


4. **Connect to the database**

	Go to Databases on RDS. Click on your db instance to find your DB Endpoints in Connectivity & Security.

	For the password, you should have this somewhere from when you created the instance. You may now use these credentials from within the MySQL HeatWave on AWS console, which we'll set up now. Just remember that your database will need some data in it! 

	Before proceeding, feel free to download some demo data and pop it in the database to play around on HeatWave -- the hard part is done!

	In RDS > Databases > (your database) you'll find endpoint info under Connectivity & security. Of course, you'll need the DNS name, username, and password before activating HeatWave as you'll use those to connect.

5. **Activate MySQL HeatWave on AWS**

	To connect our HeatWave cluster to our MySQL AWS database, we need to activate it.

	Navigate your browser to <http://cloud.mysql.com/>.

	Click Sign Up.

	A field is displayed for entering your email address. Once you enter your email, you're  directed to an Account Information page for creating an Oracle Cloud account, which is required to use MySQL HeatWave on AWS. Once you verify your email, you'll go to a page for verifying the email address and providing initial account information. Follow the prompts.

	After providing the initial account information, you are directed to a Get Started page in the Oracle Cloud Infrastructure (OCI) Console. Click the _Enable MySQL HeatWave on AWS_ link in the Quickstarts section of the page.

	You are directed to a MySQL HeatWave on AWS Administration page where you'll see a dialog which will guide you through the setup process. Note that a paid account is required. Once your upgrade is complete you'll wind up on the OCI Console.

	From the OCI Console navigation menu, select _Databases_. MySQL HeatWave on AWS appears on the Home tab under the Featured label.

	Under MySQL HeatWave on AWS, click _Administration_.

	Click _Provision_ to provision MySQL HeatWave on AWS.

	After the provisioning operation is completed, a message appears stating that MySQL HeatWave on AWS is ready and you're presented with options to open the MySQL HeatWave console, set up users, and view billing information.

### Summary - So far!

Thus far we've created a MySQL database on AWS and activated an OCI account and MySQL HeatWave on AWS using our shiny new Oracle account. Using our login for our database, we can use this tool to run queries impossibly fast -- and we're just getting started!

Want to know more? Join the discussion in our [public Slack channel](https://bit.ly/odevrel_slack)!




