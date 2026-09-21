process variantQC {
   tag "${project_id}"
   cache 'lenient'
   container 'ghcr.io/bimberlab/discvrseq:latest'
   containerOptions "-v ${params.refdir}:/ref"
   publishDir params.out , mode: 'copy'
   cpus 4
   memory '16 GB'

   input:
   tuple val(project_id), path(join_vcf), path(vcf_index)

   output:
   tuple val(project_id), path("variant_stats/${project_id}_variantQC.html"), emit: summary_QC

   script:
   // El contenedor lo administra Nextflow (directiva container), NO un 'docker run'
   // dentro del script: asi hereda docker.runOptions, el cpuset y la limpieza al abortar.
   def xmx = task.memory ? (task.memory.toGiga() * 0.8) as int : 12
   """
   mkdir -p variant_stats

   java -Xmx${xmx}g -XX:ParallelGCThreads=2 -jar /DISCVRSeq.jar VariantQC \\
        -R /ref/${params.refname} \\
        -V ${join_vcf} \\
        -O variant_stats/${project_id}_variantQC.html \\
        --threads ${task.cpus}
   """
}
