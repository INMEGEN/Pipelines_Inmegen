process genomicsDBimport {
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/genomicsdb", mode:'copy'

    input:
    path(gvcf_files)
    path(tbi_files)
    val(project_id)
    file(interval_list)

    output:
    tuple val(project_id), path("${project_id}_database"), emit: genomics_db

    script:

    def merge_intervals = params.wes == "true" ? "--merge-input-intervals" : ""

    """
    for f in *.g.vcf.gz; do
    sample=\$(basename \$f _raw_variants.g.vcf.gz)
    echo -e "\${sample}\t\${f}"
    done >> cohort.sample_map

    mkdir -p genomicsdb/tmp

    gatk --java-options "-Xms32g -Xmx32g" GenomicsDBImport \
       --genomicsdb-workspace-path ${project_id}_database \
       --batch-size ${params.batchsize} \
       --sample-name-map cohort.sample_map \
       --interval-merging-rule ALL \
       -L "${interval_list}" \
       $merge_intervals \
       --tmp-dir genomicsdb/tmp \
       --reader-threads ${params.ncrs} \
       --max-num-intervals-to-import-in-parallel ${params.ncrs}

    rm -r genomicsdb/tmp
    """
}
