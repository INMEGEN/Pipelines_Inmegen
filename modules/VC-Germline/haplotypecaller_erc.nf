process haplotypeCallerERC {
    tag "${sample_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/hc_gvcfs", mode:'copy'
    cpus 4
    memory '16 GB'

    input:
    tuple val(sample_id), path(input_bam)

    output:
    tuple val(sample_id), path("${sample_id}_raw_variants.g.vcf.gz"), emit: hc_erc_out
    path("${sample_id}_raw_variants.g.vcf.gz.tbi"),                   emit: hc_erc_index

    script:
    def xmx = task.memory ? (task.memory.toGiga() * 0.8) as int : 12
    """
    gatk --java-options "-Xmx${xmx}g -XX:ParallelGCThreads=2" HaplotypeCaller \\
        -R /ref/${params.refname} \\
        -I ${input_bam} \\
        -O ${sample_id}_raw_variants.g.vcf.gz \\
        -max-mnp-distance 0 \\
        -ERC GVCF \\
        --kmer-size 10 --kmer-size 25 --kmer-size 35 \\
        --max-reads-per-alignment-start 100 \\
        --native-pair-hmm-threads ${task.cpus} \\
        -G StandardAnnotation \\
        -G StandardHCAnnotation \\
        -G AS_StandardAnnotation
    """
}
