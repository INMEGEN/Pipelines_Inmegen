process snpEff_clinical {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:An1'
    containerOptions "-v ${params.snpsift_db}:/databases"
    publishDir params.out + "/snpEff_clinical", mode: 'copy'
 
    input:
    tuple val(project_id), path(vcf), path(tbi)

    output:
    tuple val(project_id), path("${project_id}_snpEff_clinical.vcf.gz"), path("${project_id}_snpEff_clinical.vcf.gz.tbi"), emit: snpeff_clinical_vcf
    tuple path("${project_id}_snpEff_stats.csv"), path("${project_id}_snpEff_stats.html"),                                 emit: snpeff_stats

    script:
    """
    snpEff -v GRCh38.mane.1.2.refseq \
        -csvStats ${project_id}_snpEff_stats.csv \
        -stats ${project_id}_snpEff_stats.html \
        -lof \
        -motif \
        -nextProt \
        -nodownload \
        ${vcf} > ${project_id}_snpEff_raw.vcf

    SnpSift annotate \
        /databases/clinvar/clinvar.vcf.gz \
        ${project_id}_snpEff_raw.vcf \
        > ${project_id}_snpEff_clinvar.vcf

    SnpSift annotate \
        /databases/gnomad/gnomad.genomes.v4.1.sites.vcf.gz \
        ${project_id}_snpEff_clinvar.vcf \
        > ${project_id}_snpEff_gnomad.vcf

    SnpSift annotate \
        /databases/cosmic/CosmicCodingMuts_v99_GRCh38.vcf.gz \
        ${project_id}_snpEff_gnomad.vcf \
        > ${project_id}_snpEff_ann.vcf

    bgzip -@ ${params.ncrs} -c ${project_id}_snpEff_ann.vcf > ${project_id}_snpEff_clinical.vcf.gz
    tabix ${project_id}_snpEff_clinical.vcf.gz

    rm -f ${project_id}_snpEff_raw.vcf \
          ${project_id}_snpEff_clinvar.vcf \
          ${project_id}_snpEff_gnomad.vcf \
          ${project_id}_snpEff_ann.vcf
    """
}
