process splitIntervals {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    containerOptions "-v ${params.refdir}:/ref"
    cpus 2
    memory '8 GB'

    input:
    path(interval_list)

    output:
    path("scattered/*.interval_list"), emit: intervals

    script:
    """
    mkdir -p scattered

    gatk --java-options "-Xmx6g -XX:ParallelGCThreads=2" SplitIntervals \\
        -R /ref/${params.refname} \\
        -L ${interval_list} \\
        --scatter-count ${params.scatter_count} \\
        --subdivision-mode BALANCING_WITHOUT_INTERVAL_SUBDIVISION_WITH_OVERFLOW \\
        -O scattered
    """
}
