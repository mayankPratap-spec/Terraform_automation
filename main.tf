resource "aws_vpc" "mayankvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.mayankvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.mayankvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mayankvpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.mayankvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "mysg" {
  name   = "web-sg"
  vpc_id = aws_vpc.mayankvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "s3" {
  bucket = "mayankpratapsinghbucket2024"
}

resource "aws_instance" "mayankserver1" {
  ami                    = "ami-07d9b9ddc6cd8dd30"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = base64encode(file("userdata.sh"))
}

resource "aws_instance" "mayankserver2" {
  ami                    = "ami-07d9b9ddc6cd8dd30"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = base64encode(file("userdata1.sh"))
}

resource "aws_lb" "loadbalancer" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "tg1" {
  name     = "target1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mayankvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.mayankserver1.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.mayankserver2.id
  port             = 80
}

/*resource "aws_lb_target_group_attachment" "attachments" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = element(aws_instance.mayankserver[*].id, count.index)
  port             = 80
}*/

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg1.arn
    type             = "forward"
  }
}




