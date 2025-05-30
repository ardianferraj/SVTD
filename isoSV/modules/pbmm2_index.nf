process PBMM2_INDEX {

    cpus 8
    memory 32.GB
    time 24.h
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by time or memory limit.\nSee .command.log in: ${task.workDir}\n\n"; return 'finish'}.call() : 'finish'}

    input:
    tuple val(sampleID), path(reference)

    output:
    tuple val(sampleID), path("${reference}.mmi"), emit: reference_index

    script:
    """
    pbmm2 index -j 4 --preset ISOSEQ ${reference} ${reference}.mmi
    """
}
