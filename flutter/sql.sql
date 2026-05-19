/*
SQLyog Community v13.3.0 (64 bit)
MySQL - 10.4.32-MariaDB : Database - shecare
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`shecare` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `shecare`;

/*Data for the table `auth_group` */

/*Data for the table `auth_group_permissions` */

/*Data for the table `auth_permission` */

insert  into `auth_permission`(`id`,`name`,`content_type_id`,`codename`) values 
(1,'Can add log entry',1,'add_logentry'),
(2,'Can change log entry',1,'change_logentry'),
(3,'Can delete log entry',1,'delete_logentry'),
(4,'Can view log entry',1,'view_logentry'),
(5,'Can add permission',2,'add_permission'),
(6,'Can change permission',2,'change_permission'),
(7,'Can delete permission',2,'delete_permission'),
(8,'Can view permission',2,'view_permission'),
(9,'Can add group',3,'add_group'),
(10,'Can change group',3,'change_group'),
(11,'Can delete group',3,'delete_group'),
(12,'Can view group',3,'view_group'),
(13,'Can add user',4,'add_user'),
(14,'Can change user',4,'change_user'),
(15,'Can delete user',4,'delete_user'),
(16,'Can view user',4,'view_user'),
(17,'Can add content type',5,'add_contenttype'),
(18,'Can change content type',5,'change_contenttype'),
(19,'Can delete content type',5,'delete_contenttype'),
(20,'Can view content type',5,'view_contenttype'),
(21,'Can add session',6,'add_session'),
(22,'Can change session',6,'change_session'),
(23,'Can delete session',6,'delete_session'),
(24,'Can view session',6,'view_session'),
(25,'Can add emergancy assist',7,'add_emergancyassist'),
(26,'Can change emergancy assist',7,'change_emergancyassist'),
(27,'Can delete emergancy assist',7,'delete_emergancyassist'),
(28,'Can view emergancy assist',7,'view_emergancyassist'),
(29,'Can add emergnecy number',8,'add_emergnecynumber'),
(30,'Can change emergnecy number',8,'change_emergnecynumber'),
(31,'Can delete emergnecy number',8,'delete_emergnecynumber'),
(32,'Can view emergnecy number',8,'view_emergnecynumber'),
(33,'Can add login',9,'add_login'),
(34,'Can change login',9,'change_login'),
(35,'Can delete login',9,'delete_login'),
(36,'Can view login',9,'view_login'),
(37,'Can add notification',10,'add_notification'),
(38,'Can change notification',10,'change_notification'),
(39,'Can delete notification',10,'delete_notification'),
(40,'Can view notification',10,'view_notification'),
(41,'Can add police station',11,'add_policestation'),
(42,'Can change police station',11,'change_policestation'),
(43,'Can delete police station',11,'delete_policestation'),
(44,'Can view police station',11,'view_policestation'),
(45,'Can add safe point',12,'add_safepoint'),
(46,'Can change safe point',12,'change_safepoint'),
(47,'Can delete safe point',12,'delete_safepoint'),
(48,'Can view safe point',12,'view_safepoint'),
(49,'Can add user',13,'add_user'),
(50,'Can change user',13,'change_user'),
(51,'Can delete user',13,'delete_user'),
(52,'Can view user',13,'view_user'),
(53,'Can add visuals',14,'add_visuals'),
(54,'Can change visuals',14,'change_visuals'),
(55,'Can delete visuals',14,'delete_visuals'),
(56,'Can view visuals',14,'view_visuals'),
(57,'Can add sub admin',15,'add_subadmin'),
(58,'Can change sub admin',15,'change_subadmin'),
(59,'Can delete sub admin',15,'delete_subadmin'),
(60,'Can view sub admin',15,'view_subadmin'),
(61,'Can add pink police',16,'add_pinkpolice'),
(62,'Can change pink police',16,'change_pinkpolice'),
(63,'Can delete pink police',16,'delete_pinkpolice'),
(64,'Can view pink police',16,'view_pinkpolice'),
(65,'Can add location',17,'add_location'),
(66,'Can change location',17,'change_location'),
(67,'Can delete location',17,'delete_location'),
(68,'Can view location',17,'view_location'),
(69,'Can add idea',18,'add_idea'),
(70,'Can change idea',18,'change_idea'),
(71,'Can delete idea',18,'delete_idea'),
(72,'Can view idea',18,'view_idea'),
(73,'Can add feedback',19,'add_feedback'),
(74,'Can change feedback',19,'change_feedback'),
(75,'Can delete feedback',19,'delete_feedback'),
(76,'Can view feedback',19,'view_feedback'),
(77,'Can add emergency request',20,'add_emergencyrequest'),
(78,'Can change emergency request',20,'change_emergencyrequest'),
(79,'Can delete emergency request',20,'delete_emergencyrequest'),
(80,'Can view emergency request',20,'view_emergencyrequest'),
(81,'Can add dangerous spot',21,'add_dangerousspot'),
(82,'Can change dangerous spot',21,'change_dangerousspot'),
(83,'Can delete dangerous spot',21,'delete_dangerousspot'),
(84,'Can view dangerous spot',21,'view_dangerousspot'),
(85,'Can add complaint',22,'add_complaint'),
(86,'Can change complaint',22,'change_complaint'),
(87,'Can delete complaint',22,'delete_complaint'),
(88,'Can view complaint',22,'view_complaint'),
(89,'Can add chat',23,'add_chat'),
(90,'Can change chat',23,'change_chat'),
(91,'Can delete chat',23,'delete_chat'),
(92,'Can view chat',23,'view_chat');

/*Data for the table `auth_user` */

/*Data for the table `auth_user_groups` */

/*Data for the table `auth_user_user_permissions` */

/*Data for the table `django_admin_log` */

/*Data for the table `django_content_type` */

insert  into `django_content_type`(`id`,`app_label`,`model`) values 
(1,'admin','logentry'),
(3,'auth','group'),
(2,'auth','permission'),
(4,'auth','user'),
(5,'contenttypes','contenttype'),
(23,'myapp','chat'),
(22,'myapp','complaint'),
(21,'myapp','dangerousspot'),
(7,'myapp','emergancyassist'),
(20,'myapp','emergencyrequest'),
(8,'myapp','emergnecynumber'),
(19,'myapp','feedback'),
(18,'myapp','idea'),
(17,'myapp','location'),
(9,'myapp','login'),
(10,'myapp','notification'),
(16,'myapp','pinkpolice'),
(11,'myapp','policestation'),
(12,'myapp','safepoint'),
(15,'myapp','subadmin'),
(13,'myapp','user'),
(14,'myapp','visuals'),
(6,'sessions','session');

/*Data for the table `django_migrations` */

insert  into `django_migrations`(`id`,`app`,`name`,`applied`) values 
(1,'contenttypes','0001_initial','2024-12-19 10:24:43.739963'),
(2,'auth','0001_initial','2024-12-19 10:24:43.936041'),
(3,'admin','0001_initial','2024-12-19 10:24:44.376357'),
(4,'admin','0002_logentry_remove_auto_add','2024-12-19 10:24:44.515426'),
(5,'admin','0003_logentry_add_action_flag_choices','2024-12-19 10:24:44.530423'),
(6,'contenttypes','0002_remove_content_type_name','2024-12-19 10:24:44.598100'),
(7,'auth','0002_alter_permission_name_max_length','2024-12-19 10:24:44.665482'),
(8,'auth','0003_alter_user_email_max_length','2024-12-19 10:24:44.686776'),
(9,'auth','0004_alter_user_username_opts','2024-12-19 10:24:44.700785'),
(10,'auth','0005_alter_user_last_login_null','2024-12-19 10:24:44.765059'),
(11,'auth','0006_require_contenttypes_0002','2024-12-19 10:24:44.773059'),
(12,'auth','0007_alter_validators_add_error_messages','2024-12-19 10:24:44.784061'),
(13,'auth','0008_alter_user_username_max_length','2024-12-19 10:24:44.803472'),
(14,'auth','0009_alter_user_last_name_max_length','2024-12-19 10:24:44.851422'),
(15,'auth','0010_alter_group_name_max_length','2024-12-19 10:24:44.871018'),
(16,'auth','0011_update_proxy_permissions','2024-12-19 10:24:44.882032'),
(17,'myapp','0001_initial','2024-12-19 10:24:45.299090'),
(18,'sessions','0001_initial','2024-12-19 10:24:46.089633');

/*Data for the table `django_session` */

insert  into `django_session`(`session_key`,`session_data`,`expire_date`) values 
('7mqgc3r2hdz0j1xjb7yjvljoa4u17lv8','ZTY4NDExYTAzNTA1OTAzYWZmZDVmNDczN2M1MDU5MmQ1NmRkMGJjMTp7ImxpZCI6MX0=','2025-01-02 10:53:52.871668');

/*Data for the table `myapp_chat` */

/*Data for the table `myapp_complaint` */

/*Data for the table `myapp_dangerousspot` */

insert  into `myapp_dangerousspot`(`id`,`place`,`photo`,`date`,`longitude`,`latitude`,`status`,`LOGIN_id`) values 
(1,'atholi','','2024-12-10','22','12','rejected',2),
(2,'mukkam','','2024-12-03','54','44','rejected',2),
(3,'vengeri','/media/20241219-160906.jpg','2024-12-19','66','454','pending',2),
(4,'calicut ','/media/20241219-161036.jpg','2024-12-19','77','66','approved',2);

/*Data for the table `myapp_emergancyassist` */

/*Data for the table `myapp_emergencyrequest` */

/*Data for the table `myapp_emergnecynumber` */

/*Data for the table `myapp_feedback` */

/*Data for the table `myapp_idea` */

/*Data for the table `myapp_location` */

/*Data for the table `myapp_login` */

insert  into `myapp_login`(`id`,`username`,`password`,`type`) values 
(1,'admin','admin','admin'),
(2,'shehin@gmail.com','456','pinkpolice'),
(3,'aiswaryaep07@gmail.com','123','subadmin'),
(4,'users@gmail.com','123456','user');

/*Data for the table `myapp_notification` */

insert  into `myapp_notification`(`id`,`date`,`description`) values 
(1,'2024-12-19','heloo everyone');

/*Data for the table `myapp_pinkpolice` */

insert  into `myapp_pinkpolice`(`id`,`vechileno`,`officername`,`place`,`post`,`district`,`state`,`email`,`phone`,`gender`,`dob`,`LOGIN_id`,`POLICESTATION_id`) values 
(1,4336,'vengeri','kozhikode','vengeri','vengeri','kerela','shehin@gmail.com',8086944928,'radio','2024-12-18',2,1);

/*Data for the table `myapp_policestation` */

insert  into `myapp_policestation`(`id`,`name`,`place`,`post`,`district`,`state`,`since`,`phone`,`email`) values 
(1,'station1','vengeri','vengeri','Kozhikode','kerela',2006,8086944928,'shehin@gmail.com');

/*Data for the table `myapp_safepoint` */

insert  into `myapp_safepoint`(`id`,`place`,`latitude`,`longitude`,`landmark`) values 
(2,'kozhikode','43','66','popular showroom');

/*Data for the table `myapp_subadmin` */

insert  into `myapp_subadmin`(`id`,`name`,`gender`,`email`,`phone`,`photo`,`LOGIN_id`) values 
(1,'aisu','female','aiswaryaep07@gmail.com',8606084336,'/media/20241219-155905.jpg',3);

/*Data for the table `myapp_user` */

insert  into `myapp_user`(`id`,`name`,`dob`,`gender`,`phone`,`email`,`place`,`post`,`district`,`state`,`photo`,`identificationmark`,`fathersname`,`mothername`,`bloodgroup`,`LOGIN_id`) values 
(1,'rocky','1970-01-13','female',8989898976,'user@gmail.com','atholi','vengeri','kozhikode','lerela','/media/20241219-161036.jpg','black mole on left ear','raju','susu','b+',4);

/*Data for the table `myapp_visuals` */

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
