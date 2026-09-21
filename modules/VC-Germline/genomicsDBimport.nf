process genomicsDBimport {
    tag "${project_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/genomicsdb", mode:'copy'
    cpus 4
    memory '40 GB'

    input:
    path(gvcf_files)
    path(tbi_files)
    val(project_id)
    file(interval_list)

    output:
    tuple val(project_id), path("${project_id}_database"), emit: genomics_db

    script:

    // params.wes se interpola para que la comparacion funcione con booleano o string.
    // --reader-threads y --max-num-intervals-to-import-in-parallel son MULTIPLICATIVOS.
    def merge_intervals = "${params.wes}" == "true" ? "--merge-input-intervals" : ""
    def xmx = task.memory ? (task.memory.toGiga() * 0.8) as int : 32

    """
    for f in *.g.vcf.gz; do
    sample=\$(basename \$f _raw_variants.g.vcf.gz)
    echo -e "\${sample}\t\${f}"
    done >> cohort.sample_map

    mkdir -p genomicsdb/tmp

    gatk --java-options "-Xms${xmx}g -Xmx${xmx}g -XX:ParallelGCThreads=2" GenomicsDBImport \\
       --genomicsdb-workspace-path ${project_id}_database \\
       --batch-size ${params.batchsize} \\
       --sample-name-map cohort.sample_map \\
       --interval-merging-rule ALL \\
       -L "${interval_list}" \\
       ${merge_intervals} \\
       --tmp-dir genomicsdb/tmp \\
       --reader-threads ${task.cpus} \\
       --max-num-intervals-to-import-in-parallel 1

    rm -r genomicsdb/tmp
    """
}
