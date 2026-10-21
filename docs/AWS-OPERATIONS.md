# AWS 배포 및 운영 문서

## 현재 구성

이 프로젝트는 EC2 인스턴스를 만들지 않는다. 실행 리소스는 Tokyo(`ap-northeast-1`)의 AWS App Runner 서비스 하나이며, 컨테이너 이미지는 같은 리전의 ECR에 저장된다.

| 항목 | 값 |
| --- | --- |
| GitHub 저장소 | `zeetee1235/algorithm-viz-dfs` |
| 배포 흐름 | `main` Push → GitHub Actions OIDC → ECR → App Runner 자동 배포 |
| App Runner 서비스 | `algorithm-viz-dfs` |
| App Runner ARN | `arn:aws:apprunner:ap-northeast-1:681498213984:service/algorithm-viz-dfs/016d1f8d13124cf49a9d7bd9370a0837` |
| App Runner URL | https://kspzzebuzp.ap-northeast-1.awsapprunner.com |
| ECR 저장소 | `681498213984.dkr.ecr.ap-northeast-1.amazonaws.com/algorithm-viz-dfs` |
| 정적 백업 URL | https://zeetee1235.github.io/algorithm-viz-dfs/ |

App Runner는 `0.25 vCPU`, `0.5 GB`, 포트 `8080`, HTTP 상태 검사 `/healthz`로 구성했다. App Runner를 멈춰도 GitHub Pages 백업은 계속 사용할 수 있다.

현재 운영 상태(2026-10-22): **PAUSED**. 시험 전에 아래 재개 절차를 실행한다.

## 사전 조건

AWS CLI는 IAM 사용자나 SSO처럼 폐기·교체 가능한 자격 증명으로 로그인한다. 루트 사용자의 액세스 키는 사용하지 않는다.

현재 로컬 AWS CLI 프로필은 `avf-deploy`이고 표준 파일 `~/.aws/credentials`에 저장되어 있다. 파일에는 비밀 값이 있으므로 Git에 추가하거나 내용을 복사하지 않는다. 명령 실행 시 프로필을 지정한다.

```bash
AWS_PROFILE=avf-deploy aws sts get-caller-identity
```

아래 명령은 저장소 루트에서 실행한다.

## 상태 확인

```bash
AWS_PROFILE=avf-deploy ./scripts/aws-service.sh status
```

`RUNNING`이면 AWS URL과 상태 검사 URL을 확인할 수 있다.

```bash
curl -fsS https://kspzzebuzp.ap-northeast-1.awsapprunner.com/healthz
```

## 시험이 끝난 뒤 일시중지

```bash
AWS_PROFILE=avf-deploy ./scripts/aws-service.sh pause
```

일시중지는 App Runner의 컴퓨팅 용량을 0으로 줄이면서 서비스 설정과 도메인을 보존한다. ECR 이미지 같은 별도 저장 리소스는 남아 있으므로 소액의 저장 비용이 계속 발생할 수 있다. 일시중지 중에는 AWS URL로 접속할 수 없다.

## 시험 전에 재개

```bash
AWS_PROFILE=avf-deploy ./scripts/aws-service.sh resume
```

`RUNNING`이 된 뒤 화면과 상태 검사를 확인한다.

```bash
AWS_PROFILE=avf-deploy ./scripts/aws-service.sh wait RUNNING
curl -fsS https://kspzzebuzp.ap-northeast-1.awsapprunner.com/healthz
```

일시중지 중 ECR의 `latest` 이미지가 바뀌었더라도 재개만으로 새 이미지가 자동 반영되지는 않는다. 재개 후 GitHub Actions의 `deploy-aws-apprunner` 워크플로를 다시 실행하거나 새 커밋을 Push한다.

## 완전 삭제

시험 환경을 다시 쓸 계획이 없을 때만 실행한다.

```bash
AWS_PROFILE=avf-deploy ./scripts/aws-service.sh delete algorithm-viz-dfs
```

삭제는 App Runner 서비스와 현재 AWS URL을 영구 제거한다. GitHub 저장소, GitHub Pages, ECR 저장소, IAM 역할은 자동으로 삭제하지 않는다. ECR과 IAM까지 없애려면 대상과 재사용 여부를 다시 확인한 뒤 별도로 정리한다.

## 자동 배포 확인

```bash
gh run list --repo zeetee1235/algorithm-viz-dfs --workflow deploy-aws-apprunner
gh run watch --repo zeetee1235/algorithm-viz-dfs RUN_ID
```

GitHub Actions는 장기 AWS 키 대신 저장소 전용 OIDC 역할을 사용한다. 저장소 변수는 다음 두 개다.

- `AWS_REGION=ap-northeast-1`
- `AWS_ROLE_ARN=arn:aws:iam::681498213984:role/AlgorithmVizGitHubECR`

## 콘솔에서 관리

Tokyo 리전 App Runner 콘솔:

https://ap-northeast-1.console.aws.amazon.com/apprunner/home?region=ap-northeast-1#/services

서비스 선택 후 **Actions → Pause**, **Resume**, 또는 **Delete**를 사용한다.

## 보안 체크

- 채팅, 로그, 저장소에 입력한 액세스 키는 즉시 폐기한다.
- 루트 계정 비밀번호를 변경하고 MFA를 활성화한다.
- 자동 배포에는 GitHub OIDC만 사용한다.
- 저장소나 GitHub Actions 로그에 비밀 값이 없는지 확인한다.

시험 종료 후에는 IAM 콘솔에서 현재 루트 액세스 키를 비활성화·삭제하고 새 키를 만들지 않는다. 이어서 루트 비밀번호를 변경하고 MFA를 확인한 후 로컬 프로필을 제거한다.

```bash
aws configure set aws_access_key_id '' --profile avf-deploy
aws configure set aws_secret_access_key '' --profile avf-deploy
```

AWS 공식 참고 문서:

- [App Runner 서비스 일시중지 및 재개](https://docs.aws.amazon.com/apprunner/latest/dg/manage-pause.html)
- [App Runner 서비스 삭제](https://docs.aws.amazon.com/apprunner/latest/dg/manage-delete.html)
