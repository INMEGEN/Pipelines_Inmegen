process bqsr {
    tag "${sample}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    containerOptions "-v ${params.refdir}:/ref"
    publishDir params.out + "/bqsr", mode:'symlink'

    input:
    tuple val(sample), path(bam), path(bam_idx)    

    output:
    tuple val(sample), path("${sample}_recalibration_data.table"), path("${sample}_post_recal_data.table"), emit: analyze_covariates
    tuple val(sample), path("${sample}_recalibrated.bam"),     emit: recalibrated_bam
    path("${sample}_recalibrated.bai")

    script:
    """
    mkdir -p tmp/bqsr/${sample}

    gatk BaseRecalibrator \
    -I ${bam} \
    -R /ref/${params.refname} \
    --known-sites /ref/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
    --known-sites /ref/Homo_sapiens_assembly38.dbsnp138.vcf \
    --known-sites /ref/Homo_sapiens_assembly38.known_indels.vcf.gz \
    --known-sites /ref/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
    -O ${sample}_recalibration_data.table \
    --tmp-dir tmp/bqsr/${sample}

    gatk ApplyBQSR \
    -R /ref/${params.refname} \
    -I ${bam} \
    -bqsr ${sample}_recalibration_data.table \
    -O ${sample}_recalibrated.bam \
    --tmp-dir tmp/bqsr/${sample}

    gatk BaseRecalibrator \
    -R /ref/${params.refname} \
    -I ${sample}_recalibrated.bam \
    --known-sites /ref/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
    --known-sites /ref/Homo_sapiens_assembly38.dbsnp138.vcf \
    --known-sites /ref/Homo_sapiens_assembly38.known_indels.vcf.gz \
    --known-sites /ref/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
    -O ${sample}_post_recal_data.table \
    --tmp-dir tmp/bqsr/${sample}

    rm -r tmp/bqsr/${sample}
    """
}
