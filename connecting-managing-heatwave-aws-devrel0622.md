---
title: Connecting To and Managing HeatWave on AWS
parent:
- tutorials
tags: 
- mysql
- database
- heatwave
- aws
categories:
- cloudapps
thumbnail: assets/a-mysqglhw-devrel0622-thmb001.png
date: 2022-10-08 17:00
description: Getting signed up, signed on, and some basic management tasks for your HeatWave on AWS cluster.
author: Victor Agreda
mrm: WWMK220224P00058
---
It’s a multi-cloud world today, and that's why MySQL HeatWave for Amazon Web Service gives you a massively parallel, high performance, in-memory query accelerator for the MySQL Database Service as a fully managed service, developed and supported by the MySQL team in Oracle. This accelerates MySQL performance by orders of magnitude for combined analytics and transactional workloads (OLAP and OLTP).

{% imgx assets/networkdiagram-hwaws-oci-devrel0622a.png %}

Oracle designed this so developers can focus on the important things, like managing data, creating schemas, and providing highly-available applications. Oracle automates tasks such as backup, recovery, and database and operating system patching.  

If you’ve never heard of HeatWave, think of it as a database query accelerator with boost buttons. One of the incredible things about Oracle MySQL HeatWave is the ability to [run analytics](https://www.oracle.com/mysql/heatwave/) directly against your existing transactional data, so there's no need to shuffle that data off to a separate system when you need to perform massively parallel analysis.  

Let’s get started!  

MySQL HeatWave on AWS resides in an Oracle-managed tenancy on AWS. You can access it from the browser-based HeatWave Console or from a MySQL client or application. For this article, we’ll just dip our toe in by signing in, provisioning the service, and seeing an overview of what the HeatWave Console offers.

## Prerequisites

The MySQL HeatWave Console supports browser platforms supported by Oracle Jet, such as the following browsers and versions:  

- Google Chrome 69 or later
- Safari 12.1 or later
- Firefox 62 or later
- The Console does not support Firefox Private Browsing.  

You’ll also need an AWS account, optionally an OCI account as well.  

Plus, you’ll need a DB System somewhere to connect to the HeatWave instance (this could be a HeatWave cluster in an OCI tenancy, for example).

## Signing Up

To sign up for MySQL HeatWave on AWS (if you don’t have an Oracle account):  

1. Navigate your browser to [cloud.mysql.com](https://cloud.mysql.com/). You are taken to the MySQL HeatWave on AWS welcome page.
2. Click _Sign Up_. A field is displayed for entering your email address.
3. Enter your email address and click Continue.  

	{% imgx assets/welcome2-mysqlhw-signup-actname-devrel0622a.png %}

	You are directed to an Account Information page for creating an Oracle Cloud account, which is required to use MySQL HeatWave on AWS.

	>**NOTE:** Do NOT change your Oracle Cloud Account name after provisioning the MySQL HeatWave on AWS service, as it can cause a loss of access to the MySQL HeatWave on AWS service, requiring Support assistance.
	{:.notice}
4. Enter the required information and click _Verify my email_. A verification email is sent to the specified address. This may take a minute!
5. In the verification email, click on the verification link.
 
	You'll be directed to a page for verifying the email address and providing initial account information. Follow the prompts. After providing the initial account information, you’ll go to a Get Started page in the Oracle Cloud Infrastructure (OCI) Console, which includes an _Enable MySQL HeatWave on AWS_ link in the Quickstarts section of the page.
6. Click _Enable MySQL HeatWave on AWS_.

	You are directed to a MySQL HeatWave on AWS Administration page where you are presented with a dialog that guides you through the setup process.

	{% imgx assets/hwaws-quickstart-enablehwaws-devrel0622a.png %}
7. A paid account is required to use MySQL HeatWave on AWS. Follow the prompts to complete the account upgrade process. You will be prompted to select an account type and payment method. When the upgrade process is complete, you are directed to the OCI Console.

	{% imgx assets/upgd-awshw-account-reqscrn-devrel0622.png %}
8. From the OCI Console navigation menu, select _Databases_. _MySQL HeatWave on AWS_ appears on the Home tab under the Featured label.
9. Under MySQL HeatWave on AWS, click _Administration_. You'll be returned to the setup dialog.
10. Click _Provision_ to provision MySQL HeatWave on AWS.

	After the provisioning operation is completed, a message appears stating that MySQL HeatWave on AWS is ready and you'll be presented with options to open the MySQL HeatWave console, set up users, and view billing information.

### For those with an existing Oracle account

MySQL HeatWave on AWS requires a subscription to the US East (Ashburn) region on OCI. MySQL HeatWave on AWS is integrated with OCI in the US East (Ashburn) region for identity and access management and billing. You are billed for the MySQL HeatWave on AWS Service in the US East (Ashburn) region.  

1. Navigate your browser to [cloud.mysql.com](https://cloud.mysql.com/). You'll be taken to the MySQL HeatWave on AWS welcome page.
2. Enter your Oracle Cloud Account name and click Continue.  

	You'll be directed to a Get Started page in the Oracle Cloud Infrastructure (OCI) Console, which includes an _Enable MySQL HeatWave on AWS_ link in the Quickstarts section of the page.
3. Click _Enable MySQL HeatWave on AWS_.
	You'll be directed to a MySQL HeatWave on AWS Administration page where you're presented with a dialog that guides you through the setup process.

	>**IMPORTANT:** A paid account is required to use MySQL HeatWave on AWS. If you do not have a paid account, follow the prompts to complete the account upgrade process. You will be prompted to select an account type and payment method. When the upgrade process is complete, you'll be directed to the OCI Console.
	{:.warn}

4. From the OCI Console navigation menu, select _Databases_.

	MySQL HeatWave on AWS appears on the Home tab under the Featured label.
5. Under MySQL HeatWave on AWS, click _Administration_.

	You’ll go back to the setup dialog.
6. Click _Provision_ to provision MySQL HeatWave on AWS.

	{% imgx assets/provision-requpg-hwaws-setup-devrel0622a.png %}

	After the provisioning operation is completed, a message appears stating that MySQL HeatWave on AWS is ready and you are presented with options to open the MySQL HeatWave console, set up users, and view billing information.

	{% imgx assets/congrats-mysqlhwaws-openconsol-devrel0622a.png %}

## Signing In

To sign in to MySQL HeatWave on AWS, you must have:

- Your Oracle Cloud Account name.

	This is the Cloud Account name you chose during account signup or that was provided to you by an Account Administrator. In either case, you can find your Cloud Account name in your Oracle Cloud Account welcome email.
- Your Cloud Account user name and password.

Let's get started!

1. Point your browser to [cloud.mysql.com](https://cloud.mysql.com/)

	You are taken to the MySQL HeatWave on AWS welcome page. You’re familiar by now with this screen.
2. Enter your Cloud Account name.
3. Click Continue.

	You'll be directed to the Oracle Cloud Account Sign In dialog.
4. Enter your user name and password and click Sign In.

	Once your user name and password are authenticated, you are directed to the HeatWave Console. Eventually you’ll need to create users and groups (for various levels of access control), and you can conveniently access the Oracle Identity Cloud Service from the MySQL HeatWave on AWS Console:

	1. Sign in to the HeatWave Console as an Account Administrator.
	2. From the profile menu, select _Administration_.
	
		You'll be directed to the MySQL HeatWave on AWS Administration page in the OCI Console.
	3. Select _Identity Service_.

		This will take you to the Identity section in the OCI Account Center.  

		{% imgx assets/mysqlhw-awsconsole-2view-signin-devrel0622a.png %}

## What’s Next?

From here, you can log into the MySQL HeatWave on AWS Console and create MySQL DB Systems and manage them, and see HeatWave Clusters, Workspaces (where you can create and run queries), and Performance (analytics) to see how efficient HeatWave is.

{% imgx assets/1-mysql-heatwave-on-aws-console-devrel-fy2361022.png %}

### Connecting to a DB System in Workspaces

By now you’ve got MySQL HeatWave on AWS provisioned, and you want to connect it to a DB System somewhere. We do this in the Workspaces tab in the console.

A Connection Information dialog will appear, and you choose a DB System from the drop-down, enter the proper username/password combo, and click _Connect_.

### Managing HeatWave Cluster Data

Also in the Workspaces tab, we can use the Console to load or unload data from a HeatWave cluster. Here’s how:

1. In the DB System workspace, expand the _Manage Data in HeatWave_ pane.
2. Select the databases and tables that you want to load or unload. Databases are selected in the Databases pane. When a database is selected, the tables from the selected database appear in the Tables from selected databases pane.
3. There’s lots to see there but we’re interested in selecting the tables we want to load or unload, so click _Load into HeatWave_ or _Unload from HeatWave_.

	If you're loading tables, the MySQL Auto Parallel Load tables into Heatwave dialog appears, providing a summary of the load operation about to happen.

4. Click Load Tables to start the parallel load operation.

	To stop a load or unload operation, click Stop Load/Unload.

	>**NOTE:** The Refresh button refreshes the page, displaying the current state of databases and tables loaded in HeatWave.
	{:.notice}

### Creating Backups

To create a DB System backup:

1. In the HeatWave Console, select the _MySQL DB Systems_ tab. Under MySQL, select _DB Systems_.
2. In the list of DB Systems, find the DB System you want to create a backup for, and do one of the following:  
	- Click on the row of the DB System to highlight it, and choose _Create Backup_ from the _Actions_ menu.
	- Click the name of the DB System to open the DB System Details page. Click _Create Backup_. The Create Backup dialog is displayed.
3. Edit the fields as required:  
	- Display Name: The name of the backup.
	
		If you do not define a name, one is generated in the format `DB-System-Name - Backup - Date&Time`.
	- Description: The description of the backup.
	 
		If you do not define a description, one is generated in the format `DB-System-Name - Manual Backup - Date&Time`.
4. Click _Create_ to create the backup.

### Maintenance

Good news! Essential patching and maintenance of MySQL DB Systems is an automatic process. Patches of the underlying operating system, and updates to versions (-uN) of the MySQL server and any underlying hardware are performed during the Maintenance Window defined on the DB System. A Maintenance Window Start Time is automatically defined for you and can be viewed on the DB System Details page in the MySQL HeatWave on AWS Console.

When maintenance is performed, your DB System's status changes to UPDATING and the DB System may be unavailable for a short time while the maintenance completes.  

Such maintenance is performed infrequently, and only when absolutely necessary. This is usually for security or reliability issues.

### Upgrading MySQL Server

Use the Console to manually upgrade the MySQL Server of your DB System.

>**NOTE:** It is recommended to perform a full backup of your DB System before upgrading.
{:.notice}

1. In the HeatWave Console, select the _MySQL DB Systems_ tab.
2. Under MySQL, select _DB Systems_.
3. Find the DB System you want to upgrade, and do one of the following:

	- Click on the row of the DB System to highlight it, and choose _Edit MySQL Version_ from the Actions menu. If this option is not enabled, your DB System is already using the latest version of the MySQL Server.
	- Click the name of the DB System to open the DB System Details page. Click _Edit MySQL Version_. If this button is not enabled, your DB System is already using the latest version of the MySQL Server.
	
	The Edit MySQL Version dialog is displayed.

4. In the Edit MySQL Version, select the required MySQL version.
5. Click _Save Changes_.

	The DB System enters the UPDATING state while the MySQL Server is upgraded.

### Managing a HeatWave Cluster

When a HeatWave cluster is stopped through a stop or restart action, the data loaded in HeatWave cluster memory is lost.

### Starting, stopping, or restarting a HeatWave Cluster

These actions have no effect on the DB System to which the HeatWave cluster is attached. However, executing start, stop, or restart actions on the DB System also affect the attached HeatWave cluster. When a HeatWave cluster is stopped as a result of a stop or restart action on the DB System, any data that was loaded on the HeatWave cluster must be reloaded when the HeatWave cluster is restarted.

To start, stop, or restart a HeatWave cluster:

1. In the HeatWave Console, select the _HeatWave Clusters_ tab.
2. In the list of HeatWave clusters, find the HeatWave cluster you want to start, stop, or restart, and do one of the following:

	- Click on the row of the HeatWave cluster to highlight it, and choose the required action from the Actions menu.
	- Click the name of the HeatWave cluster to open the HeatWave Cluster Details page. On this page you can stop, start, or restart the HeatWave cluster.

3. Select one of the following actions:

	- _Start_: Starts a stopped HeatWave cluster. After the HeatWave cluster is started, the Stop action is enabled and the Start option is disabled.
	- _Stop_: Stops a running HeatWave cluster. After the HeatWave cluster is stopped, the Start action is enabled.
	- _Restart_: Shuts down a HeatWave cluster and restarts it.

### Deleting a HeatWave Cluster

Deleting a HeatWave cluster removes the HeatWave cluster nodes permanently. The DB System to which the HeatWave cluster is attached is unaffected. Perhaps you just want to crunch some data for a bit, while keeping costs low. Bear in mind that the cluster will need to be set up from scratch again after deletion.

To delete a HeatWave cluster:

1. In the HeatWave Console, select the _HeatWave Clusters_ tab.
2. In the list of HeatWave clusters, find the HeatWave cluster you want to delete, and do one of the following:

	- Click on the row of the HeatWave cluster to highlight it, and choose the _Delete_ action from the _Actions_ menu.
	- Click the name of the HeatWave cluster to open the HeatWave Cluster Details page. Click the _Delete_ button.
	
		The Delete HeatWave Cluster dialog is displayed.

3. Click _Delete HeatWave cluster_.

That's a top-level overview of getting your HeatWave on AWS set up, and a little bit of management.  

Want to know more? Join the discussion in our [public Slack channel](https://bit.ly/odevrel_slack)!
