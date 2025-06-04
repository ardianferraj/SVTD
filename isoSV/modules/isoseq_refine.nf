process ISOSEQ_REFINE {

    tag "$sampleID"

    cpus 6
    memory 24.GB
    time 6.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    container = "/projects/chesler-lab/csna/sv_ferraj/SVTD/repo/isoSV/containers/isoSV.sif"

    publishDir "${params.pubdir}/${sampleID}/isoseq/refine", mode: "copy"

    input:
    tuple val(sampleID), path(hifi_bam), path(primer_fasta)

    output:
    tuple path("${sampleID}_flnc.bam"), emit: flnc_bam

    script:
    """
    isoseq refine \
    ${hifi_bam} \
    ${primer_fasta} \
    ${sampleID}_flnc.bam
    """
}