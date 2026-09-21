process genotypeGVCFs {
    tag "${interval.simpleName}"
    cache 'lenient'
    containerOptions "-v ${params.refdir}:/ref"
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    cpus 2
    memory '12 GB'

    input:
    tuple val(project_id), path(database), path(interval)

    output:
    tuple val(project_id), path("${interval.simpleName}_raw.vcf.gz"), path("${interval.simpleName}_raw.vcf.gz.tbi"), emit: shard_vcf

    script:
    """
    gatk --java-options "-Xmx10g -XX:ParallelGCThreads=2" GenotypeGVCFs \\
        -R /ref/${params.refname} \\
        -V gendb://${database} \\
        -L ${interval} \\
        --genomicsdb-shared-posixfs-optimizations true \\
        -O ${interval.simpleName}_raw.vcf.gz
    """
}

