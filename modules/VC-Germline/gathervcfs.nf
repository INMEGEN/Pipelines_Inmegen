process gatherVcfs {
    tag "${project_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/raw_vcfs", mode:'copy'
    cpus 2
    memory '16 GB'

    input:
    tuple val(project_id), path(vcfs), path(tbis)

    output:
    tuple val(project_id), path("${project_id}_raw_variants.vcf.gz"), path("${project_id}_raw_variants.vcf.gz.tbi"), emit: gvcfs_out

    script:
    """
    ls *_raw.vcf.gz | sort -V > vcf.list

    gatk --java-options "-Xmx12g -XX:ParallelGCThreads=2" MergeVcfs \\
        -I vcf.list \\
        -O ${project_id}_raw_variants.vcf.gz
    """
}
