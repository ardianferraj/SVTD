process PBMM2_ALIGN {

    tag "$sampleID"

    cpus 16
    memory 48.GB
    time 24.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    publishDir "${params.pubdir}/${sampleID}/", mode: "copy"

    input:
    tuple val(sampleID), path(clustered_bam), path(reference), path(reference_index)

    output:
    tuple val(sampleID), path("${sampleID}_mapped.bam"), emit: mapped_bam
    tuple val(sampleID), path("${sampleID}_mapped.bam.bai"), emit: mapped_bam_index

    script:
    """
    pbmm2 align -j 16 --preset ISOSEQ --sort ${reference} ${clustered_bam} ${sampleID}_mapped.bam
    """
}
