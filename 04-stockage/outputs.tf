output "object_bucket" {
  description = "Bucket S3 (object storage)"
  value       = aws_s3_bucket.benchmark_object.id
}

output "block_volume_id" {
  description = "Volume EBS (block storage)"
  value       = aws_ebs_volume.benchmark_block.id
}

output "block_volume_size" {
  description = "Taille du volume EBS (Go)"
  value       = aws_ebs_volume.benchmark_block.size
}
