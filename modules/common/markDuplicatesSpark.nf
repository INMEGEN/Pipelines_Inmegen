process markDuplicatesSpark {
    tag "${sample_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/dedup_sorted", mode:'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}_alineamiento.bam"), path("${sample_id}_alineamiento.bam.bai"),   emit: bam_dedup
    tuple val(sample_id), path("${sample_id}_dedup_metrics.txt"),   emit: dedup_qc

    script:
    def xmx = (task.memory.toGiga() * 0.85) as int
    """
    mkdir -p markduplicates/${sample_id}/spark_tmp

    gatk --java-options "-Xmx${xmx}g -XX:ActiveProcessorCount=${task.cpus} -XX:ParallelGCThreads=2" \\
        MarkDuplicatesSpark \\
        -I ${bam} \\
        -M ${sample_id}_dedup_metrics.txt \\
        -O ${sample_id}_alineamiento.bam \\
        --tmp-dir markduplicates/${sample_id} \\
        --spark-master local[${task.cpus}] \\
        --conf spark.local.dir=\$PWD/markduplicates/${sample_id}/spark_tmp \\
        --conf spark.ui.enabled=false

    rm -r markduplicates/${sample_id}
}
