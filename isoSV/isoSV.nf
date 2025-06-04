#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// load modules
include { ISOSEQ_CLUSTER } from './modules/isoseq_cluster2.nf'
include { PBMM2_INDEX } from './modules/pbmm2_index.nf'
include { PBMM2_ALIGN } from './modules/pbmm2_align.nf'
include { ISOSEQ_COLLAPSE } from './modules/isoseq_collapse.nf'
include { PIGEON_CLASSIFY } from './modules/pigeon.nf'
include { SQANTI_QC } from './modules/sqanti_qc.nf'
include { SQANTI_FILTER } from './modules/sqanti_filter.nf'

// custom script to extract CSV sample sheet
include { extract_csv } from './bin/extract_csv.nf'

// ==================
// PARAMETERS & INPUT
// ==================

// extract sample info from CSV
if (params.csv_input) {
    // csv format:
    // sampleID, flnc_bam_path, reference_fasta_path, reference_gtf_path, shortread_fofn_path

    ch_input_sample = extract_csv(file(params.csv_input, checkIfExists: true))

    // set up channels
    ch_input_sample.map { row -> 
        tuple(row[0], file(row[1]), file(row[2]), file(row[3]), file(row[4]))
    }.set { sample_ch }
}

ch_input_sample.subscribe { println "Sample info: $it" }

workflow {
    // -----------------
    // 1. CLUSTER
    // -----------------
    ISOSEQ_CLUSTER(
        sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf, shortread_fofn -> 
            tuple(sampleID, flnc_bam)
        }
    )
    
    // Get the main output from ISOSEQ_CLUSTER
    clustered_bam_ch = ISOSEQ_CLUSTER.out.clustered_bam

    // -----------------
    // 2. INDEX REFERENCE
    // -----------------
    PBMM2_INDEX(
        sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf, shortread_fofn -> 
            tuple(sampleID, reference_fasta)
        }
    )
    
    // Get the reference index from PBMM2_INDEX
    reference_index_ch = PBMM2_INDEX.out.reference_index
    
    // -----------------
    // 3. ALIGN
    // -----------------
    // First, extract reference fasta from sample_ch to use for joining
    reference_fasta_ch = sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf, shortread_fofn -> 
        tuple(sampleID, reference_fasta)
    }
    
    // Now join the clustered BAM with the reference and index
    // We need to join by sampleID which is the first element in each tuple
    align_input_ch = clustered_bam_ch
        .join(reference_fasta_ch)
        .join(reference_index_ch)
        .map { sampleID, clustered_bam, reference_fasta, reference_index ->
            tuple(sampleID, clustered_bam, reference_fasta, reference_index)
        }

    // Run the alignment process
    PBMM2_ALIGN(align_input_ch)
    
    // Get the mapped BAM from PBMM2_ALIGN
    mapped_bam_ch = PBMM2_ALIGN.out.mapped_bam
    
    // -----------------
    // 4. COLLAPSE
    // -----------------
    // Run isoseq collapse to generate GFF
    ISOSEQ_COLLAPSE(mapped_bam_ch)
    
    // Get the collapsed GFF
    collapsed_gff_ch = ISOSEQ_COLLAPSE.out.collapse_gff
    
    // -----------------
    // 5. SQANTI3 QC
    // -----------------
    // Prepare input for SQANTI3 QC by joining with reference files and short read FOFN
    reference_files_ch = sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf, shortread_fofn -> 
        tuple(sampleID, reference_fasta, reference_gtf, shortread_fofn)
    }
    
    sqanti_qc_input_ch = collapsed_gff_ch
        .join(reference_files_ch)
        .map { sampleID, collapsed_gff, reference_fasta, reference_gtf, shortread_fofn ->
            tuple(sampleID, collapsed_gff, reference_fasta, reference_gtf, shortread_fofn)
        }
    
    // Run SQANTI3 QC
    SQANTI_QC(sqanti_qc_input_ch)
    
    // Get SQANTI3 QC outputs
    sqanti_classification_ch = SQANTI_QC.out.classification
    sqanti_junctions_ch = SQANTI_QC.out.junctions
    sqanti_corrected_fasta_ch = SQANTI_QC.out.corrected_fasta
    sqanti_corrected_gtf_ch = SQANTI_QC.out.corrected_gtf
    
    // -----------------
    // 6. SQANTI3 Filter
    // -----------------
    // Prepare input for SQANTI3 Filter
    sqanti_filter_input_ch = sqanti_classification_ch
        .join(sqanti_corrected_fasta_ch)
        .join(sqanti_corrected_gtf_ch)
        .join(sqanti_junctions_ch)
        .map { sampleID, classification_txt, corrected_fasta, corrected_gtf, junctions_txt ->
            tuple(sampleID, classification_txt, corrected_fasta, corrected_gtf, junctions_txt)
        }
    
    // Run SQANTI3 Filter
    SQANTI_FILTER(sqanti_filter_input_ch)
    
    // Optional: continue with classify step
    // PIGEON_CLASSIFY(...)
}