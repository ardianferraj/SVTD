process PIGEON_CLASSIFY {

    tag "$sampleID"

    cpus 16
    memory 48.GB
    time 24.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    publishDir "${params.pubdir}/${sampleID}/", mode: "copy"

    input:
    tuple val(sampleID), path(collapse_gff), path(reference_gtf), path(reference_fasta)

    output:
    tuple val(sampleID), path("${sampleID}_classification.txt"), emit: classification_out

    script:
    """
    # prepare reference files
    pigeon prepare ${reference_gtf} ${reference_fasta}

    # Sort collapsed GFF first
    pigeon prepare ${collapse_gff}

    # Run pigeon classify
    pigeon classify \$(basename ${collapse_gff} .gff).sorted.gff ${reference_gtf} ${reference_fasta} > ${sampleID}_classification.txt
    """
}