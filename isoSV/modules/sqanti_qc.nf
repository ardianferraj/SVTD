process SQANTI_QC {

    tag "$sampleID"

    cpus 32
    memory 64.GB
    time 12.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    container = "/projects/chesler-lab/csna/sv_ferraj/SVTD/repo/isoSV/containers/isoSV.sif"

    publishDir "${params.pubdir}/${sampleID}/sqanti_qc/", mode: "copy"

    input:
    tuple val(sampleID), path(collapsed_gff), path(reference_fasta), path(reference_gtf), path(shortread_fofn)

    output:
    tuple val(sampleID), path("${sampleID}_classification.txt"), emit: classification
    tuple val(sampleID), path("${sampleID}_junctions.txt"), emit: junctions
    tuple val(sampleID), path("${sampleID}_corrected.fasta"), emit: corrected_fasta
    tuple val(sampleID), path("${sampleID}_corrected.gtf"), emit: corrected_gtf
    tuple val(sampleID), path("${sampleID}*.html"), emit: report_html, optional: true

    script:
    // Handle optional short read FOFN
    def shortread_arg = shortread_fofn.name != 'NO_FILE' ? "--short_reads ${shortread_fofn}" : ""
    
    """
    # fix later, sqanti bug: https://github.com/ConesaLab/SQANTI3/issues/456
    mkdir -p example/rescue_ml/logs
    
    # Run SQANTI3 QC with minimal inputs and disable rescue functionality
    python /opt/SQANTI3/sqanti3_qc.py \\
        --isoforms ${collapsed_gff} \\
        --refGTF ${reference_gtf} \\
        --refFasta ${reference_fasta} \\
        --cpus ${task.cpus} \\
        --output ${sampleID} \\
        --dir . \\
        --report html \\
        --force_id_ignore \\
        --skipORF \\
        ${shortread_arg}
    
    # Verify main outputs exist
    if [ ! -f "${sampleID}_classification.txt" ]; then
        echo "Error: Classification file not created"
        exit 1
    fi
    
    if [ ! -f "${sampleID}_junctions.txt" ]; then
        echo "Error: Junctions file not created"
        exit 1
    fi
    
    if [ ! -f "${sampleID}_corrected.gtf" ]; then
        echo "Error: Corrected GTF file not created"
        exit 1
    fi
    
    if [ ! -f "${sampleID}_corrected.fasta" ]; then
        echo "Error: Corrected FASTA file not created"
        exit 1
    fi
    
    echo "SQANTI3 QC completed successfully for ${sampleID}"
    """
}