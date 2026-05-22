# 1. Create the OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 2. Build the Trust Policy restricting access to your specific repository
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:0dow0ri7s3/epicbook-app:*", "repo:devopenginelab/epicbook-app:*"]
    }
  }
}

# 3. Create the IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name               = "epicbook-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}
