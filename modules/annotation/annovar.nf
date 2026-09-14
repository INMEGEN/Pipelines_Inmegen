process annovar {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:An2'
    containerOptions "-v ${params.annovar_db}:/humandb"
    publishDir params.out + "/annovar", mode: 'copy'

    input:
    tuple val(sample), path(filtered_vcf), path(filtered_vcf_idx)

    output:
    tuple val(sample),
          path("${sample}_annovar.hg19_multianno.vcf.gz"),
          path("${sample}_annovar.hg19_multianno.vcf.gz.tbi"), emit: annovar_ch_vcf
    tuple val(sample),
          path("${sample}_annovar.hg19_multianno.txt"),        emit: annovar_ch_txt
    path("*.avinput")

    script:
    def protocol = [
        "refGene", "refGeneWithVer", "ensGene",
        "avsnp151",
        "clinvar_20240917",
        "gnomad211_genome", "gnomad211_exome",
        "esp6500siv2_all",
        "dbnsfp47a", "dbnsfp47a_interpro", "dbscsnv11",
        "cadd", "caddindel",
        "intervar_20180118",
        "cosmic70"
    ].join(",")
    def operation = [
        "g", "g", "g",
        "f", "f", "f", "f", "f",
        "f", "f", "f", "f", "f",
        "f", "f"
    ].join(",")
    """
    table_annovar ${filtered_vcf} /humandb/ \\
        --buildver hg19 \\
        --out ${sample}_annovar \\
        --remove \\
        --protocol ${protocol} \\
        --operation ${operation} \\
        --vcfinput \\
        --thread ${task.cpus} \\
        --nastring . \\
        --polish

    txt_cols=\$(grep -m1 "^Chr" ${sample}_annovar.hg19_multianno.txt | awk -F'\t' '{print NF}')
    vcf_cols=\$(grep -m1 "^#CHROM" ${sample}_annovar.hg19_multianno.vcf | awk -F'\t' '{print NF}')
    diff=\$(( txt_cols - vcf_cols ))

    if [ "\${diff}" -gt 0 ]; then
        header_patch=\$(grep -m1 "^Chr" ${sample}_annovar.hg19_multianno.txt \\
            | cut -f1-\${diff})
        vcf_header=\$(grep -m1 "^#CHROM" ${sample}_annovar.hg19_multianno.vcf)
        sed -i "s|^#CHROM.*|\${header_patch}\t\${vcf_header}|" \\
            ${sample}_annovar.hg19_multianno.vcf
    fi

    bgzip -c ${sample}_annovar.hg19_multianno.vcf \\
        > ${sample}_annovar.hg19_multianno.vcf.gz
    tabix ${sample}_annovar.hg19_multianno.vcf.gz
    """
}
