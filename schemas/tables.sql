-- Database: lrg
-- ------------------------------------------------------


--
-- Table structure for table `contact`
--
CREATE TABLE `contact` (
  `contact_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `url` varchar(255) default NULL,
  `address` varchar(255) default NULL,
  `phone` varchar(255) default NULL,
  `fax` varchar(255) default NULL,
  `is_requester` tinyint(1) default 0,
  PRIMARY KEY  (`contact_id`),
  UNIQUE KEY `name` (`name`)
);

--
-- Table structure for table `gene`
--
CREATE TABLE `gene` (
  `gene_id` int(11) NOT NULL auto_increment,
  `symbol` varchar(64) default NULL,
  `hgnc_id` int(11) default NULL, 
  `ncbi_gene_id` int(11) default NULL,
  `refseq` varchar(64) default NULL,
  `lrg_id` varchar(64) default NULL,
  `status` enum('stalled','pending','public') default NULL,
  PRIMARY KEY  (`gene_id`),
  UNIQUE KEY `symbol` (`symbol`),
  UNIQUE KEY `lrg_id` (`lrg_id`),
  UNIQUE KEY `ncbi_gene_id` (`ncbi_gene_id`),
  UNIQUE KEY `hgnc_id` (`hgnc_id`),
  KEY `symbol_idx` (`symbol`),
  KEY `lrg_idx` (`lrg_id`)
);

--
-- Table structure for table `lrg_annotation_set`
--
CREATE TABLE `lrg_annotation_set` (
  `annotation_set_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `type` enum('lrg','ncbi','ensembl') default NULL,
  `source` int(11) NOT NULL,
  `comment` text,
  `modification_date` date NOT NULL,
  `lrg_gene_name` varchar(255) default NULL,
  `xml` mediumtext,
  PRIMARY KEY  (`annotation_set_id`),
  UNIQUE KEY `gene_id` (`gene_id`,`source`)
);

--
-- Table structure for table `lrg_annotation_set_mapping`
--
CREATE TABLE `lrg_annotation_set_mapping` (
  `annotation_set_id` int(11) NOT NULL,
  `mapping_id` int(11) NOT NULL,
  PRIMARY KEY  (`annotation_set_id`,`mapping_id`)
);

--
-- Table structure for table `lrg_cdna`
--
CREATE TABLE `lrg_cdna` (
  `cdna_id` int(11) NOT NULL auto_increment,
  `transcript_id` int(11) NOT NULL,
  `lrg_start` int(11) NOT NULL,
  `lrg_end` int(11) NOT NULL,
  PRIMARY KEY  (`cdna_id`),
  UNIQUE KEY `transcript_id` (`transcript_id`)
);

--
-- Table structure for table `lrg_cdna_sequence`
--
CREATE TABLE `lrg_cdna_sequence` (
  `cdna_id` int(11) NOT NULL,
  `sequence_id` int(11) NOT NULL,
  PRIMARY KEY  (`cdna_id`,`sequence_id`)
);

--
-- Table structure for table `lrg_cds`
--
CREATE TABLE `lrg_cds` (
  `cds_id` int(11) NOT NULL auto_increment,
  `transcript_id` int(11) NOT NULL,
  `lrg_start` int(11) NOT NULL,
  `lrg_end` int(11) NOT NULL,
  `codon_start` int(11) default NULL,
  PRIMARY KEY  (`cds_id`),
  KEY `transcript_id` (`transcript_id`)
);

--
-- Table structure for table `lrg_cds_exception`
--
CREATE TABLE `lrg_cds_exception` (
  `exception_id` int(11) NOT NULL auto_increment,
  `cds_id` int(11) NOT NULL,
  `sequence_id` int(11) NOT NULL,
  `codon` int(11) NOT NULL,
  PRIMARY KEY  (`exception_id`),
  KEY `cds_idx` (`cds_id`),
  KEY `sequence_idx` (`sequence_id`)
);

--
-- Table structure for table `lrg_cds_frameshift`
--
CREATE TABLE `lrg_cds_frameshift` (
  `frameshift_id` int(11) NOT NULL auto_increment,
  `cds_id` int(11) NOT NULL,
  `cdna_pos` int(11) NOT NULL,
  `frameshift` tinyint(4) NOT NULL,
  PRIMARY KEY  (`frameshift_id`),
  KEY `cds_idx` (`cds_id`)
);


--
-- Table structure for table `lrg_comment`
--
CREATE table `lrg_comment` (
  `comment_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `comment` text default NULL,
  PRIMARY KEY  (`comment_id`),
  KEY `id_idx` (`gene_id`,`name`)
);

--
-- Table structure for table `lrg_curator`
--
CREATE TABLE `lrg_curator` (
  `lrg_id` varchar(64) NOT NULL,
  `curator` enum('Jackie','Joannella','Aoife','John') NOT NULL,
  PRIMARY KEY  (`lrg_id`,`curator`)
);

--
-- Table structure for table `lrg_data`
--
CREATE TABLE `lrg_data` (
  `gene_id` int(11) NOT NULL,
  `organism` varchar(255) NOT NULL,
  `taxon_id` int(11) NOT NULL,
  `moltype` varchar(16) NOT NULL default 'dna',
  `initial_creation_date` date default NULL,
  `creation_date` date default NULL,
  PRIMARY KEY  (`gene_id`)
);

--
-- Table structure for table `lrg_exon`
--
CREATE TABLE `lrg_exon` (
  `exon_id` int(11) NOT NULL auto_increment,
  `exon_label` varchar(55) NOT NULL,
  `transcript_id` int(11) NOT NULL,
  `lrg_start` int(11) NOT NULL,
  `lrg_end` int(11) NOT NULL,
  `cdna_start` int(11) default NULL,
  `cdna_end` int(11) default NULL,
  PRIMARY KEY  (`exon_id`),
  KEY `transcript_idx` (`transcript_id`)
);

--
-- Table structure for table `lrg_exon_peptide`
--
CREATE TABLE `lrg_exon_peptide` (
  `exon_peptide_id` int(11) NOT NULL auto_increment,
  `exon_id` int(11) NOT NULL,
  `peptide_start` int(11) default NULL,
  `peptide_end` int(11) default NULL,
  `peptide_name` varchar(25) NOT NULL,
  PRIMARY KEY  (`exon_peptide_id`),
  KEY `exon_idx` (`exon_id`)
);

--
-- Table structure for table `lrg_genomic_sequence`
--
CREATE TABLE `lrg_genomic_sequence` (
  `gene_id` int(11) NOT NULL,
  `sequence_id` int(11) NOT NULL,
  PRIMARY KEY  (`gene_id`,`sequence_id`)
);

--
-- Table structure for table `lrg_intron`
--
CREATE TABLE `lrg_intron` (
  `intron_id` int(11) NOT NULL auto_increment,
  `exon_5` int(11) NOT NULL,
  `exon_3` int(11) NOT NULL,
  `phase` int(11) NOT NULL,
  PRIMARY KEY  (`intron_id`),
  UNIQUE KEY `exon_5` (`exon_5`,`exon_3`)
);

--
-- Table structure for table `lrg_mapping`
--
CREATE TABLE `lrg_mapping` (
  `mapping_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `assembly` varchar(32) NOT NULL,
  `chr_name` varchar(32) NOT NULL,
  `chr_id` varchar(32) NOT NULL,
  `chr_start` int(11) NOT NULL,
  `chr_end` int(11) NOT NULL,
  `chr_syn` varchar(255) default NULL,
  `type` enum('main_assembly','other_assembly','patch','haplotype','transcript') default 'other_assembly',
  PRIMARY KEY  (`mapping_id`),
  UNIQUE KEY `gene_mapping_idx` (`gene_id`,`assembly`,`chr_name`,`chr_id`)
);

--
-- Table structure for table `lrg_mapping_diff`
--
CREATE TABLE `lrg_mapping_diff` (
  `mapping_diff_id` int(11) NOT NULL auto_increment,
  `mapping_span_id` int(11) NOT NULL,
  `type` enum('mismatch','lrg_ins','other_ins') NOT NULL,
  `chr_start` int(11) NOT NULL,
  `chr_end` int(11) NOT NULL,
  `lrg_start` int(11) NOT NULL,
  `lrg_end` int(11) NOT NULL,
  `lrg_sequence` text,
  `chr_sequence` text,
  PRIMARY KEY  (`mapping_diff_id`),
  KEY `mapping_span_id` (`mapping_span_id`)
);

--
-- Table structure for table `lrg_mapping_span`
--
CREATE TABLE `lrg_mapping_span` (
  `mapping_span_id` int(11) NOT NULL auto_increment,
  `mapping_id` int(11) NOT NULL,
  `lrg_start` int(11) NOT NULL,
  `lrg_end` int(11) NOT NULL,
  `chr_start` int(11) NOT NULL,
  `chr_end` int(11) NOT NULL,
  `strand` int(11) NOT NULL,
  PRIMARY KEY  (`mapping_span_id`),
  KEY `mapping_id` (`mapping_id`)
);

--
-- Table structure for table `lrg_note`
--
CREATE TABLE `lrg_note` (
  `note_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `annotation_set` enum('lrg','ncbi','ensembl','requester','community') default 'requester',
  `author` varchar(255) default NULL, -- Possibly change to contact ID in the future
  `note` text default NULL,
  PRIMARY KEY  (`note_id`),
  KEY `id_idx` (`gene_id`)
);

--
-- Table structure for table `lrg_peptide`
--
CREATE TABLE `lrg_peptide` (
  `peptide_id` int(11) NOT NULL auto_increment,
  `cds_id` int(11) NOT NULL,
  `peptide_name` varchar(64) NOT NULL default 'p1',
  PRIMARY KEY  (`peptide_id`),
  KEY `cds_id` (`cds_id`)
);

--
-- Table structure for table `lrg_peptide_sequence`
--
CREATE TABLE `lrg_peptide_sequence` (
  `peptide_id` int(11) NOT NULL,
  `sequence_id` int(11) NOT NULL,
  PRIMARY KEY  (`peptide_id`,`sequence_id`)
);

--
-- Table structure for table `lrg_request`
--
CREATE TABLE `lrg_request` (
  `gene_id` int(11) NOT NULL,
  `lsdb_id` int(11) NOT NULL,
  PRIMARY KEY  (`gene_id`,`lsdb_id`)
);

--
-- Table structure for table `lrg_sequence`
--
CREATE TABLE `lrg_sequence` (
  `sequence_id` int(11) NOT NULL auto_increment,
  `sequence` text NOT NULL,
  PRIMARY KEY  (`sequence_id`)
);

--
-- Table structure for table `lrg_status`
--
CREATE TABLE `lrg_status` (
  `lrg_status_id` int(11) NOT NULL auto_increment,
  `lrg_id` varchar(64) NOT NULL,
  `title` varchar(128) default NULL,
  `status` enum('in progress','pending','public','stalled') default 'pending',
  `description` text,
  `lrg_step_id` enum('1','2','3','4','5','6','7','8','9','10','11','12') default NULL,
  `from_date` date default NULL,
  `to_date` date default NULL,
  PRIMARY KEY  (`lrg_status_id`),
  KEY `lrg_step_idx` (`lrg_step_id`)
);

--
-- Table structure for table `lrg_status_backup`
--
CREATE TABLE `lrg_status_backup` (
  `lrg_id` varchar(64) NOT NULL,
  `status` enum('in progress','pending','public','stalled') default 'stalled',
  `comment` text,
  `updated` date default NULL
);

--
-- Table structure for table `lrg_step`
--
CREATE TABLE `lrg_step` (
  `lrg_step_id` tinyint(1) UNSIGNED NOT NULL auto_increment,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY  (`lrg_step_id`)
);

--
-- Table structure for table `lrg_transcript`
--
CREATE TABLE `lrg_transcript` (
  `transcript_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `transcript_name` varchar(64) NOT NULL default 't1',
  PRIMARY KEY  (`transcript_id`),
  UNIQUE KEY `gene_id` (`gene_id`,`transcript_name`)
);

--
-- Table structure for table `lrg_transcript_date`
--
CREATE TABLE `lrg_transcript_date` (
  `gene_id` int(11) NOT NULL,
  `transcript_name` varchar(64) NOT NULL default 't1',
  `creation_date` date NOT NULL,
  PRIMARY KEY  (`gene_id`,`transcript_name`)
);

--
-- Table structure for table `lsdb`
--
CREATE TABLE `lsdb` (
  `lsdb_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `url` varchar(255) default NULL,
	`code` varchar(255) default NULL,
	`manually_modif` tinyint(1) default 0,
	`manually_modif_date` date default NULL,
  PRIMARY KEY  (`lsdb_id`)
);

--
-- Table structure for table `lsdb_contact`
--
CREATE TABLE `lsdb_contact` (
  `lsdb_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  PRIMARY KEY  (`lsdb_id`,`contact_id`)
);

--
-- Table structure for table `lsdb_gene`
--
CREATE TABLE `lsdb_gene` (
  `lsdb_id` int(11) NOT NULL,
  `gene_id` int(11) NOT NULL,
  PRIMARY KEY  (`lsdb_id`,`gene_id`)
);

--
-- Table structure for table `lsdb_deleted`
--
CREATE TABLE `lsdb_deleted` (
 `lsdb_id` int(11) NOT NULL,
 `name` varchar(255) DEFAULT NULL,
 `url` varchar(255) DEFAULT NULL,
 `manually_modif_date` date DEFAULT NULL,
 `deletion_date` date NOT NULL,
 `genes` varchar(255) DEFAULT NULL,
 `contacts` varchar(255) DEFAULT NULL,
 `reason` varchar(255) DEFAULT NULL,
 PRIMARY KEY  (`lsdb_id`)
);

--
-- Table structure for table `meta`
--
CREATE TABLE `meta` (
  `meta_id` int(11) NOT NULL auto_increment,
  `meta_key` varchar(40) NOT NULL,
  `meta_value` varchar(255) NOT NULL,
  PRIMARY KEY  (`meta_id`)
);

--
-- Table structure for table `other_exon`
--
CREATE TABLE `other_exon` (
  `other_exon_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `lrg_id` varchar(64) NOT NULL,
  `transcript_name` varchar(64) NOT NULL default 't1',
  `description` varchar(255) NOT NULL,
  `url` varchar(255) default NULL,
  `comment` text default NULL,
  PRIMARY KEY  (`other_exon_id`),
  KEY (`gene_id`)
);

--
-- Table structure for table `other_exon_label`
--
CREATE TABLE `other_exon_label` (
  `other_exon_id` int(11) NOT NULL,
  `other_exon_label` varchar(255) NOT NULL,
  `lrg_exon_label` varchar(55) NOT NULL,
  PRIMARY KEY  (`other_exon_id`,`other_exon_label`)
);


--
-- Table structure for table `other_exon`
--
CREATE TABLE `other_aa` (
  `other_aa_id` int(11) NOT NULL auto_increment,
  `gene_id` int(11) NOT NULL,
  `lrg_id` varchar(64) NOT NULL,
  `transcript_name` varchar(64) NOT NULL default 't1',
  `description` varchar(255) NOT NULL,
  `url` varchar(255) default NULL,
  `comment` text default NULL,
  PRIMARY KEY  (`other_aa_id`),
  KEY (`gene_id`)
);

--
-- Table structure for table `other_exon_label`
--
CREATE TABLE `other_aa_number` (
  `other_aa_id` int(11) NOT NULL,
  `lrg_start` int(11) NOT NULL,
  `lrg_end` int(11) NOT NULL,
  `start` int(11) NOT NULL,
  `end` int(11) NOT NULL,
  KEY  (`other_aa_id`)
);

--
-- Table structure for table `refseq_sequence_tail`
--
CREATE TABLE `refseq_sequence_tail` (
  `name` varchar(50) NOT NULL,
  `sequence` text NOT NULL,
  PRIMARY KEY (`name`)
);

--
-- Table structure for table `requester_in_fixed`
--
CREATE TABLE `requester_in_fixed` (
  `gene_id` int(11) NOT NULL,
  PRIMARY KEY  (`gene_id`)
);

INSERT INTO meta (meta_key,meta_value) VALUES ('schema','1.9');
