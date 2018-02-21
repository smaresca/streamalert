// IAM Role: Rule Processor Execution Role
resource "aws_iam_role" "streamalert_rule_processor_role" {
  name = "${var.prefix}_${var.cluster}_streamalert_rule_processor_role"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

// IAM Policy Doc: Generic Lambda AssumeRole
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "stream_alert_rule_processor_cloudwatch" {
  role       = "${aws_iam_role.streamalert_rule_processor_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// IAM Role Policy: Allow the Rule Processor to invoke the Alert Processor
resource "aws_iam_role_policy" "streamalert_rule_processor_lambda" {
  name = "LambdaInvokeAlertProcessor"
  role = "${aws_iam_role.streamalert_rule_processor_role.id}"

  policy = "${data.aws_iam_policy_document.rule_processor_invoke_alert_proc.json}"
}

// IAM Policy Doc: Allow the Rule Processor to invoke the Alert Processor
data "aws_iam_policy_document" "rule_processor_invoke_alert_proc" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    # Use interpolation because of the different VPC/non vpc resources
    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.prefix}_streamalert_alert_processor",
    ]
  }
}

// IAM Role Policy: Allow the Rule Processor to put data on Firehose
resource "aws_iam_role_policy" "streamalert_rule_processor_firehose" {
  name = "FirehoseWriteData"
  role = "${aws_iam_role.streamalert_rule_processor_role.id}"

  policy = "${data.aws_iam_policy_document.streamalert_rule_processor_firehose.json}"
}

// IAM Policy Doc: Allow the Rule Processor to PutRecord* on any StreamAlert Firehose
data "aws_iam_policy_document" "streamalert_rule_processor_firehose" {
  statement {
    effect = "Allow"

    actions = [
      "firehose:PutRecord*",
      "firehose:DescribeDeliveryStream",
      "firehose:ListDeliveryStreams",
    ]

    resources = [
      "arn:aws:firehose:${var.region}:${var.account_id}:deliverystream/streamalert_data_*",
    ]
  }
}

// IAM Role Policy: Allow Rule Processor to read DynamoDB table (Threat Intel)
resource "aws_iam_role_policy" "streamalert_rule_processor_dynamodb" {
  count  = "${var.threat_intel_enabled ? 1 : 0}"
  name   = "ReadDynamodb"
  role   = "${aws_iam_role.streamalert_rule_processor_role.id}"
  policy = "${data.aws_iam_policy_document.streamalert_rule_processor_read_dynamodb.json}"
}

// IAM Policy Doc: Allow lambda function to read/write data from DynamoDB
data "aws_iam_policy_document" "streamalert_rule_processor_read_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_ioc_table}",
    ]
  }
}
