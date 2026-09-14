process genotypeGVCFs {
    cache 'lenient'
    containerOptions "-v ${params.refdir}:/ref"
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/raw_vcfs", mode:'copy'
    cpus 2
    memory '90 GB'    

    input:
    tuple val(project_id), path(database)

    output:
    tuple val(project_id), path("${project_id}_raw_variants.vcf.gz"), path("${project_id}_raw_variants.vcf.gz.tbi"), emit: gvcfs_out

    script:
    """
    gatk --java-options "-Xmx85g -XX:+UseParallelGC" GenotypeGVCFs \
     -R /ref/${params.refname} \
     -V gendb://${database} \
     --genomicsdb-shared-posixfs-optimizations true \
     -O ${project_id}_raw_variants.vcf.gz 
    """
}

