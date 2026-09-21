#!/usr/bin/env nextflow
// Workflow    : Identificación conjunta de variantes germinales
// Institución : Instituto Nacional de Medicina Genómica (INMEGEN)
// Maintainer  : Subdirección de genómica poblacional y subdirección de bioinformática
// Versión     : 1.2
// Docker image - pipelinesinmegen/pipelines_inmegen -

nextflow.enable.dsl=2

// Processes for this workflow
// Pre-processing
include { fastqc as fastqc_raw               } from "../modules/qualitycontrol/fastqc.nf"
include { fastqc as fastqc_trim              } from "../modules/qualitycontrol/fastqc.nf"
include { fastqScreen                        } from "../modules/qualitycontrol/fastq_screen.nf"
include { multiqc                            } from "../modules/qualitycontrol/multiqc.nf"
include { fastp                              } from "../modules/VC-Germline/fastp.nf"
include { align                              } from "../modules/VC-Germline/bwa_germline.nf"
include { mergeBam                           } from "../modules/VC-Germline/mergebamfiles.nf"
include { markDuplicatesSpark                } from "../modules/common/markDuplicatesSpark.nf"
include { getMetrics                         } from "../modules/metrics/getmetrics.nf"
include { metricswes                         } from "../modules/metrics/metrics_wes.nf"
include { metricswgs                         } from "../modules/metrics/metrics_wgs.nf"
include { summary_wes                        } from "../modules/metrics/summary_wes.nf"
include { summary_wgs                        } from "../modules/metrics/summary_wgs.nf"
include { bqsr                               } from "../modules/VC-Germline/bqsr_recal.nf"
include { analyzeCovariates                  } from "../modules/common/analyzecovariates.nf"

// DeepVariant
include { deepVariant                        } from "../modules/VC-Germline/deepvariant.nf"
include { glnexus                            } from "../modules/VC-Germline/glnexus.nf"

// GATK
include { haplotypeCallerERC                 } from "../modules/VC-Germline/haplotypecaller_erc.nf"
include { genomicsDBimport                   } from "../modules/VC-Germline/genomicsDBimport.nf"
include { genotypeGVCFs                      } from "../modules/VC-Germline/genotypegvcfs.nf"
include { splitIntervals                     } from "../modules/VC-Germline/splitintervals.nf"
include { gatherVcfs                         } from "../modules/VC-Germline/gathervcfs.nf"
include { selectVariants                     } from "../modules/VC-Germline/selectvariants.nf"
include { vqsrsnps                           } from "../modules/VC-Germline/vqsr_snps.nf"
include { vqsrindels                         } from "../modules/VC-Germline/vqsr_indels.nf"
include { joinvcfs                           } from "../modules/VC-Germline/joinvcfs.nf"

// Filters
include { ensembleVariants                   } from "../modules/VC-Germline/ensemble.nf"
include { variantQC                          } from "../modules/metrics/variantQC.nf"
include { postfiltervcf                      } from "../modules/VC-Germline/postfilter.nf"

// Annotation
include { annovar                            } from "../modules/annotation/annovar.nf"
include { snpEff                             } from "../modules/annotation/snpEff.nf"
include { snpSift                            } from "../modules/annotation/snpSift.nf"
include { splitVCFs as splitVCFs_variantes   } from "../modules/annotation/splitvcf.nf"
include { splitVCFs as splitVCFs_anotadas    } from "../modules/annotation/splitvcf.nf"

workflow {

    log.info """
====================================================
                Pipelines INMEGEN
     Identificación de variantes germinales
====================================================

Docker image      : pipelinesinmegen/pipelines_inmegen
Proyecto          : ${params.project_id}
Muestras          : ${params.sample_info}
Tipo de análisis  : ${"${params.wes}" == "true" ? 'WES' : 'WGS'}
Múltiples lanes   : ${params.multiple_lanes}
Referencia        : ${params.refdir}
Build (ANNOVAR)   : ${params.buildver}
Base snpEff       : ${params.snpeff_db}
DeepVariant       : ${params.run_deepvariant}
Anotación         : ${params.run_annotation}
Fastq_Screen      : ${params.run_fastqscreen}
Directorio salida : ${params.out}

====================================================
"""

// Declare some parameters

   bed_file      = file("${params.bed_file}")
   bed_filew     = file("${params.bed_filew}")
   interval_list = file("${params.interval_list}")
   adapters      = file("${params.adapters}")
   fqs_config    = file("${params.fqscreen_config}")

// === Samples ====================================================

   Channel.fromPath("${params.sample_info}" )
          .splitCsv(sep:"\t", header: true)
          .map { row ->  def sample = "${row.SampleID}"
                         def sample_id = "${row.Sample_name}"
                         def PU = "${row.RG_PU}"
                         def PL = "${row.RG_PL}"
                         def LB = "${row.RG_LB}"
                         def R1 = file("${row.R1}")
                         def R2 = file("${row.R2}")
                 return [ sample, sample_id, PU, PL, LB , R1, R2 ]
               }
          .set { read_pairs_ch }

// === QC =========================================================

    fastqc_raw(read_pairs_ch)

    if ("${params.run_fastqscreen}" == "true") {
        read_pairs_ch
            .map { sample, sample_id, PU, PL, LB, R1, R2 -> tuple(sample_id, R1, R2) }
            .set { fqscreen_ch }

        fastqScreen(fqscreen_ch,fqs_config)
    }

    fastp(read_pairs_ch,adapters)
    fastqc_trim(fastp.out.trim_fq)

// === Align and metrics ==========================================

    align(fastp.out.trim_fq)

    if ("${params.multiple_lanes}" == "true") {
        align.out.aligned_reads.collect().flatten().collate(2)
            .map { sample_id, bam ->
                   def key = sample_id.toString().tokenize('_').get(0)
                   return tuple(key, bam)
                  }.groupTuple() | mergeBam

       markDuplicatesSpark(mergeBam.out.merged_bam)
       } else {
       markDuplicatesSpark(align.out.aligned_reads)
    }

    if ("${params.wes}" == "true"){
    metricswes(markDuplicatesSpark.out.bam_dedup,bed_file,bed_filew)
    summary_wes(metricswes.out.summary_file.collect(),"${params.project_id}","${params.out}"+"/metrics/summary")
    }
    else {
    metricswgs(markDuplicatesSpark.out.bam_dedup)
    summary_wgs(metricswgs.out.summary_file.collect(),"${params.project_id}","${params.out}"+"/metrics/summary")
    }

   getMetrics(markDuplicatesSpark.out.bam_dedup)

// === Base quality recalibration ============================

   bqsr(markDuplicatesSpark.out.bam_dedup)
   analyzeCovariates(bqsr.out.analyze_covariates)

// === Variant calling GATK ==================================

   haplotypeCallerERC(bqsr.out.recalibrated_bam)

   hc_out = haplotypeCallerERC.out.hc_erc_out
       .map { sample_id, gvcf -> gvcf }
       .collect()

   hc_idx = haplotypeCallerERC.out.hc_erc_index
       .collect()

   genomicsDBimport(hc_out, hc_idx, "${params.project_id}", interval_list)

   splitIntervals(interval_list)

   gdb_x_intervals = genomicsDBimport.out.genomics_db
       .combine(splitIntervals.out.intervals.flatten())

   genotypeGVCFs(gdb_x_intervals)

   shards_agrupados = genotypeGVCFs.out.shard_vcf.groupTuple()

   gatherVcfs(shards_agrupados)

   selectVariants(gatherVcfs.out.gvcfs_out)

   vqsrsnps(selectVariants.out.snps_ch)
   vqsrindels(selectVariants.out.indels_ch)

   joinvcfs(vqsrsnps.out.snps_filt_ch,vqsrindels.out.indels_filt_ch)

// === DeepVariant + GLnexus + Ensemble =======================

   if ("${params.run_deepvariant}" == "true") {
       deepVariant(markDuplicatesSpark.out.bam_dedup,"${params.bed_file}")

         dv_gvcf = deepVariant.out.dv_gvcf_out.map { sample_id, gvcf, tbi -> gvcf }.collect()
         dv_tbi = deepVariant.out.dv_gvcf_out.map { sample_id, gvcf, tbi -> tbi }.collect()

       glnexus(dv_gvcf, dv_tbi, "${params.project_id}", interval_list)
       ensembleVariants(joinvcfs.out.join_vars_filt, glnexus.out.dv_joint_vcf)

       clinical_vcf = ensembleVariants.out.consensus_vcf
       ensemble_vcf = ensembleVariants.out.ensemble_vcf
    } else {
       clinical_vcf = joinvcfs.out.join_vars_filt
       ensemble_vcf = joinvcfs.out.join_vars_filt
    }

// === QC & filters ===========================================

   variantQC(ensemble_vcf)
   postfiltervcf(ensemble_vcf)

// === Anotación de variantes =================================

   splitVCFs_variantes(postfiltervcf.out.filt_pass_vcf,"variantes")

   if ("${params.run_annotation}" == "true") {

       annovar(postfiltervcf.out.filt_pass_vcf)
       snpEff(annovar.out.annovar_ch_vcf)
       snpSift(snpEff.out.snpeff_ch_vcf)

       splitVCFs_anotadas(snpSift.out.snpsift_ch_vcf,"anotadas")

       annot_reports = snpEff.out.snpeff_ch_txt.collect()
    } else {
       annot_reports = Channel.empty()
    }

// === Summary ================================================

    reports_ch = ensemble_vcf.collect()
                    .concat(postfiltervcf.out.filt_pass_vcf.collect())
                    .concat(annot_reports)
                    .collect()

    mqc_config = file("${params.mqc_config}")

    multiqc(reports_ch,mqc_config,"${params.out}")

}
