#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// load modules
include { ISOSEQ_CLUSTER } from './modules/isoseq_cluster2.nf'
include { PBMM2_INDEX } from './modules/pbmm2_index.nf'
include { PBMM2_ALIGN } from './modules/pbmm2_align.nf'
include { ISOSEQ_COLLAPSE } from './modules/isoseq_collapse.nf'
include { PIGEON_CLASSIFY } from './modules/pigeon.nf'

// custom script to extract CSV sample sheet
include { extract_csv } from './bin/extract_csv.nf'

// ==================
// PARAMETERS & INPUT
// ==================

// extract sample info from CSV
if (params.csv_input) {
    // csv format:
    // sampleID, flnc_bam_path, reference_fasta_path, reference_gtf_path

    ch_input_sample = extract_csv(file(params.csv_input, checkIfExists: true))

    // set up channels
    ch_input_sample.map { row -> 
        tuple(row[0], file(row[1]), file(row[2]), file(row[3]))
    }.set { sample_ch }
}

ch_input_sample.subscribe { println "Sample info: $it" }

workflow {
    // -----------------
    // 1. CLUSTER
    // -----------------
    ISOSEQ_CLUSTER(
        sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf -> 
            tuple(sampleID, flnc_bam)
        }
    )
    
    // Get the main output from ISOSEQ_CLUSTER
    clustered_bam_ch = ISOSEQ_CLUSTER.out.clustered_bam

    // -----------------
    // 2. INDEX REFERENCE
    // -----------------
    PBMM2_INDEX(
        sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf -> 
            tuple(sampleID, reference_fasta)
        }
    )
    
    // Get the reference index from PBMM2_INDEX
    reference_index_ch = PBMM2_INDEX.out.reference_index
    
    // -----------------
    // 3. ALIGN
    // -----------------
    // First, extract reference fasta from sample_ch to use for joining
    reference_fasta_ch = sample_ch.map { sampleID, flnc_bam, reference_fasta, reference_gtf -> 
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
    
    // Optionally continue with classify step
    // PIGEON_CLASSIFY(...)

    // -----------------
    // 5. SQANTI3 QC
    // -----------------
    // sample_ch
    //     .combine(collapsed_gff_ch)
    //     .map { [ [sampleID, flnc_bam, reference_fasta, reference_gtf], (collapsed_sampleID, collapsed_gff, collapsed_fasta, collapsed_txt, collapsed_json) ] ->
    //         // pass collapsed_fasta to SQANTI3
    //         def shortread_fofn = file("/dev/null")  // or a real file if you want
    //         tuple(sampleID, collapsed_fasta, reference_gtf, reference_fasta, shortread_fofn)
    //     }
    //     .set { sqanti3_input_ch }

    // SQANTI3_QC(sqanti3_input_ch)
}