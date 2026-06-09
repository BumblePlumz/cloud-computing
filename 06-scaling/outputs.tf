output "asg_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "asg_capacity" {
  description = "Capacité min / désirée / max"
  value       = "min=${aws_autoscaling_group.app.min_size} desired=${aws_autoscaling_group.app.desired_capacity} max=${aws_autoscaling_group.app.max_size}"
}

output "scale_out_policy" {
  value = aws_autoscaling_policy.scale_out.arn
}
