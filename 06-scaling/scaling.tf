# ── Auto Scaling : ajuste automatiquement le nombre d'instances ───

# 1. Launch Template : la config de CHAQUE instance créée par l'ASG
resource "aws_launch_template" "app" {
  name_prefix   = "scaling-app-"
  image_id      = "ami-12345678"   # AMI factice (mock LocalStack)
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Petit serveur HTTP lancé au démarrage de chaque instance
    python3 -m http.server 8080 &
    echo "Instance demarree : $(hostname)" > /tmp/status
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "scaling-app-instance" }
  }
}

# 2. Auto Scaling Group : min 1, max 5, démarre à 1
resource "aws_autoscaling_group" "app" {
  name                = "scaling-app-asg"
  min_size            = 1
  max_size            = 5
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "scaling-app-asg"
    propagate_at_launch = true
  }
}

# 3. Politique SCALE OUT : charge haute -> +2 instances
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 120
}

# 4. Alarme CPU > 70% pendant 2 min -> déclenche scale out
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "scaling-cpu-high-70"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions    = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

# 5. Politique SCALE IN : charge faible -> -1 instance
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# 6. Alarme CPU < 20% pendant 5 min -> déclenche scale in
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "scaling-cpu-low-20"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20

  dimensions    = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}
