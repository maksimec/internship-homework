```markdown
# AWS Cloud Internship — Homework INT26-14

> **Cohort:** INT26 · **Trainee:** maksimecv  
> **Repository path:** `INT26-14/`  
> **Stack:** AWS (Free Tier) · IAM · Route 53 · Billing & Cost Management

---

## Зміст

- [Таска 1 — Порівняльна таблиця провайдерів](#таска-1--порівняльна-таблиця-провайдерів)
- [Таска 2 — IAM User з обмеженим dev-доступом](#таска-2--iam-user-з-обмеженим-dev-доступом)
- [Таска 3 — Identity Center SSO](#таска-3--identity-center-sso-пропущено)
- [Таска 4 — Billing: доступ, бюджет, алерти](#таска-4--billing-доступ-бюджет-алерти)
- [Таска 5 — Route 53 + DNS міграція](#таска-5--route-53--dns-міграція)
- [Prerequisites](#prerequisites)

---

## Prerequisites

Перед виконанням завдань 2, 4 та 5 було підготовлено базову інфраструктуру в AWS акаунті (Free Tier):

| Ресурс | Назва | Теги |
|---|---|---|
| IAM Group | `Admins` | — |
| IAM User (адміністратор) | `maksimec10` | — |
| EC2 Instance (t3.micro) | `internship2026-ec2-dev` | `environment=dev` |
| EC2 Instance (t3.micro) | `internship2026-ec2-prod` | `environment=prod` |
| S3 Bucket | `internship2026-bucket-*` | `environment=dev` |
| Security Group | `internship2026-basicsg` | SSH: власна IP/32 · HTTP/HTTPS: 0.0.0.0/0 |

> **Примітка щодо безпеки:** SSH-доступ (порт 22) обмежений лише адміністраторською IP-адресою (`/32`). Режим CPU Credits для EC2 встановлено як `standard` (не `unlimited`) для уникнення зайвих витрат у Free Tier.

---

## Таска 1 — Порівняльна таблиця провайдерів

**`[HW] Cloud Providers: порівняльна таблиця AWS vs GCP vs Azure vs Hetzner`**

Дослідження та порівняння чотирьох cloud-провайдерів за критеріями: вартість обчислювальних ресурсів, зберігання, мережевого трафіку, managed-сервісів, дисконтних програм, регіональної присутності та відповідності GDPR.

**Результат:** [`task_1/comparison_table_of_providers.pdf`](task_1/comparison_table_of_providers.pdf)
https://docs.google.com/spreadsheets/d/1lchwz-BEHLdp-lkNe1LnVATvRJrkX3K3FvMfvVeb26M/view

### Ключові висновки

| Сценарій | Рекомендований провайдер |
|---|---|
| Якщо немає прив'язки до екосистеми, потрібен найбільший вибір managed-сервісів, велике ком'юніті та найвища гнучкість архітектури | AWS |
| Якщо є прив'язка до екосистеми (умовно той же сервіс Google Workspace) | GCP |
| Якщо є прив'язка до екосистеми (Microsoft: AD, C#, Windows Server) | Azure |
| Для стартапів, тестових оточень або мікросервісів, де потрібна умовна Cloud гнучкість, але без переплат за бренд та managed-services великої трійки | Hetzner Cloud |
| Для проєктів, де стабільне передбачуване навантаження, яке планується на певний період. При цьому жертвуємо миттєвим масштабуванням + беремо на себе ризики апаратних збоїв | Hetzner Bare Metal |

---

## Таска 2 — IAM User з обмеженим dev-доступом

**`[HW] AWS IAM: User, Group, Policy — read-only доступ до dev ресурсів`**

Створення IAM-інфраструктури для dev-розробника з доступом виключно до ресурсів середовища `dev`.

---

### Sub-task 1: Розмітка ресурсів тегами

Теги `environment=dev` та `environment=prod` додано до EC2-інстансів та S3-бакету через AWS Resource Explorer.

| Скріншот | Опис |
|---|---|
| [`subtask_1/aws_resourse_explorer_filter_by_dev.png`](task_2/subtask_1/aws_resourse_explorer_filter_by_dev.png) | Ресурси з тегом `environment=dev` |
| [`subtask_1/aws_resourse_explorer_filter_by_prod.png`](task_2/subtask_1/aws_resourse_explorer_filter_by_prod.png) | Ресурси з тегом `environment=prod` |

---

### Sub-task 2: Створення IAM Policy `DevReadOnlyByTag`

Політика надає мінімально необхідний доступ (Principle of Least Privilege):

- **Allow:** `ec2:Describe*`, `rds:Describe*`, `s3:GetObject`, `s3:ListBucket` — тільки для ресурсів з тегом `environment=dev`
- **Deny:** усі дії на ресурси з тегом `environment=prod` (explicit deny, має пріоритет над будь-яким allow)
- **Allow:** `iam:Get*`, `iam:List*`, `cloudwatch:Describe*` — глобально, без прив'язки до тегів

Повний JSON документ політики: [`subtask_2/DevReadOnlyByTag.json`](task_2/subtask_2/DevReadOnlyByTag.json)

| Скріншот | Опис |
|---|---|
| [`subtask_2/IAM_policy_version.png`](task_2/subtask_2/IAM_policy_version.png) | Створена версія політики в консолі IAM |

---

### Sub-task 3: Створення IAM Group та User

| Сутність | Назва | Конфігурація |
|---|---|---|
| IAM Group | `dev-readonly-team` | Прикріплена політика: `DevReadOnlyByTag` |
| IAM User | `dev.viewer` | Член групи: `dev-readonly-team` |

| Скріншот | Опис |
|---|---|
| [`subtask_3/IAM_group_permissions.png`](task_2/subtask_3/IAM_group_permissions.png) | Прикріплена до групи політика |
| [`subtask_3/IAM_user_groups.png`](task_2/subtask_3/IAM_user_groups.png) | Членство користувача у групі |
| [`subtask_3/IAM_user_permissions.png`](task_2/subtask_3/IAM_user_permissions.png) | Зведені права користувача `dev.viewer` |

---

### Sub-task 4: Перевірка доступів

**IAM Policy Simulator:** `ec2:DescribeInstances` → `Allowed` · `ec2:StopInstances` (prod) → `Denied`

**CLI-перевірка:**
```bash
# Перевірка поточного контексту
aws sts get-caller-identity

# Перегляд інстансів з тегом dev (дозволено)
aws ec2 describe-instances --filters "Name=tag:environment,Values=dev"

# Спроба зупинки інстансів (очікуваний результат: UnauthorizedOperation)
aws ec2 stop-instances --instance-ids i-02ff0e30c90a4bb92
aws ec2 stop-instances --instance-ids i-0ea1a90e6d373186f
```

| Скріншот | Опис |
|---|---|
| [`subtask_4/IAM_policy_simulator.png`](task_2/subtask_4/IAM_policy_simulator.png) | Результати IAM Policy Simulator |
| [`subtask_4/cmd_testing_permissions.png`](task_2/subtask_4/cmd_testing_permissions.png) | CLI-перевірка зазначених у тасці команд |

---

## Таска 3 — Identity Center SSO (пропущено)

**`[HW] AWS Identity Center: SSO User, Groups, 2 Permission Sets, CLI перевірка`**

> ⚠️ **Статус: ПРОПУЩЕНО** відповідно до Q&A-сесії від 24.04.2026.  
> **Причина:** активація AWS Identity Center вимагає створення AWS Organization, що при Free Tier акаунті може спричинити зміну умов білінгу та активацію платних сервісів. Інтерни переходять безпосередньо до Таски 4 та подальшої роботи з VPC.

---

## Таска 4 — Billing: доступ, бюджет, алерти

**`[HW] AWS Billing: доступ для IAM, бюджет з алертами 50/70/90%, Cost Anomaly Detection`**

Налаштування повного контролю витрат у AWS акаунті: від активації доступу до білінгу для IAM-користувачів до автоматичних бюджетних дій.

---

### Sub-task 1: Доступ до Billing для IAM

Активовано опцію **IAM user and role access to Billing information** через Root-акаунт (`Account → IAM user and role access → Activate`). Після активації IAM-адміністратор отримав повний доступ до Billing Dashboard без використання Root-акаунту.

| Скріншот | Опис |
|---|---|
| [`subtask_1/IAM_user_access_to_billing.png`](task_4/subtask_1/IAM_user_access_to_billing.png) | Налаштування активації доступу |
| [`subtask_1/IAM_user_testing_access_to_billing.png`](task_4/subtask_1/IAM_user_testing_access_to_billing.png) | IAM-користувач успішно бачить Billing Dashboard |

---

### Sub-task 2: Cost Allocation Tags

Тег `environment` активовано в розділі **Billing → Cost Allocation Tags**. Активація набирає чинності протягом 24 годин після увімкнення.

| Скріншот | Опис |
|---|---|
| [`subtask_2/cost_allocation_tags.png`](task_4/subtask_2/cost_allocation_tags.png) | Тег `environment` активовано |

---

### Sub-task 3: Бюджет з алертами

Створено бюджет `monthly-total-budget` ($10/міс) з трьома порогами сповіщень:

| Threshold | Тип | Канал |
|---|---|---|
| 50% ($5.00) | Actual Cost | Email + Amazon SNS |
| 70% ($7.00) | Actual Cost | Email + Amazon SNS |
| 90% ($9.00) | Actual Cost | Email + Amazon SNS |

| Скріншот | Опис |
|---|---|
| [`subtask_3/billing_and_cost_management_monthly-total-budget.png`](task_4/subtask_3/billing_and_cost_management_monthly-total-budget.png) | Деталі створеного бюджету |

---

### Sub-task 4: Cost Anomaly Detection

Створено монітор аномалій типу **AWS Services**:

| Параметр | Значення |
|---|---|
| Monitor name | `AWSServicesMonitor` |
| Subscription name | `AnomalyAlert` |
| Threshold | $10 above expected spend |
| Alerting frequency | Individual alerts |
| Delivery | Amazon SNS → Email |

| Скріншот | Опис |
|---|---|
| [`subtask_4/cost_anomaly_detection_monitor.png`](task_4/subtask_4/cost_anomaly_detection_monitor.png) | Активний монітор аномалій |

---

### Sub-task 5: Cost Explorer

Досліджено розподіл витрат за трьома зрізами та збережено звіти:

| Звіт | Group by | Мета |
|---|---|---|
| `Top Services` | Service | Які AWS-сервіси генерують найбільші витрати |
| `Region Costs` | Region | Виявлення неочікуваних активних регіонів |

| Скріншот | Опис |
|---|---|
| [`subtask_5/cost_explorer.png`](task_4/subtask_5/cost_explorer.png) | Cost Explorer зі збереженими звітами |

---

### Sub-task 6 (бонус): Budget Actions

До бюджету `monthly-total-budget` додано автоматичну дію при досягненні 100% порогу:

| Параметр | Значення |
|---|---|
| Threshold | 100% Actual Cost |
| Action type | Stop EC2 instances |
| IAM Role | `AWSBudgetsActionsRole` |
| Approval model | Automatic |

| Скріншот | Опис |
|---|---|
| [`subtask_6/adding_alert_for_cost_100.png`](task_4/subtask_6/adding_alert_for_cost_100.png) | Конфігурація порогу 100% |
| [`subtask_6/if_cost_100_then_stop_instances.png`](task_4/subtask_6/if_cost_100_then_stop_instances.png) | Налаштована автоматична дія зупинки інстансів |

---

## Таска 5 — Route 53 + DNS міграція

**`[HW] ⭐ Route 53: Hosted Zone + міграція NS та домену`**

Перенесення управління DNS-зоною власного домену до AWS Route 53 з прив'язкою до EC2-інстансу через Elastic IP.

---

### Sub-task 1: Фіксація поточного стану DNS

Зафіксовано всі існуючі записи (A, CNAME, MX, TXT, NS) у поточного реєстратора. TTL знижено до 3600 секунд (найменше можливе значення у доменного реєстратора nic.ua) для прискорення розповсюдження змін.

| Скріншот | Опис |
|---|---|
| [`subtask_1/current_dns_records.png`](task_5/subtask_1/current_dns_records.png) | Поточні DNS-записи у реєстратора |

---

### Sub-task 2: Створення Hosted Zone

Створено Public Hosted Zone у Route 53. Отримано 4 NS-сервери AWS (вигляд: `ns-XXX.awsdns-YY.com`).

| Скріншот | Опис |
|---|---|
| [`subtask_2/created_hosted_zone.png`](task_5/subtask_2/created_hosted_zone.png) | Створена Hosted Zone з NS-записами |

---

### Sub-task 3: Перенесення DNS-записів

Виділено Elastic IP та прив'язано до EC2-інстансу `internship2026-ec2-dev`. Створено A-запис у Route 53.

| Скріншот | Опис |
|---|---|
| [`subtask_4/associated_elastic_ip.png`](task_5/subtask_3/associated_elastic_ip.png) | Elastic IP, прив'язана до EC2 |
| [`subtask_3/configured_dns_zone.png`](task_5/subtask_3/configured_dns_zone.png) | DNS-зона з перенесеними записами |

---

### Sub-task 4: Зміна NS у реєстратора

Замінено NS-записи реєстратора на чотири сервери AWS. Налаштовано режим Custom Nameservers.

| Скріншот | Опис |
|---|---|
| [`subtask_4/configured_custom_ns.png`](task_5/subtask_4/configured_custom_ns.png) | Custom NS у панелі реєстратора |

---

### Sub-task 5: Перевірка міграції

```bash
# Перевірка NS-записів
dig NS maksimecv.pp.ua +short
dig NS maksimecv.pp.ua @8.8.8.8

# Перевірка A-запису безпосередньо через AWS NS
dig A maksimecv.pp.ua @ns-988.awsdns-59.net +short

# Перевірка TTL
dig A maksimecv.pp.ua +noall +answer
```

| Скріншот | Опис |
|---|---|
| [`subtask_5/cmd_checking_domain_migration.png`](task_5/subtask_5/cmd_checking_domain_migration.png) | Результати `dig` — NS вказують на AWS, A-запис повертає Elastic IP |

---

## Структура репозиторію

```
INT26-14/
├── task_1/
│   └── comparison_table_of_providers.pdf
├── task_2/
│   ├── subtask_1/
│   │   ├── aws_resourse_explorer_filter_by_dev.png
│   │   └── aws_resourse_explorer_filter_by_prod.png
│   ├── subtask_2/
│   │   ├── DevReadOnlyByTag.json
│   │   └── IAM_policy_version.png
│   ├── subtask_3/
│   │   ├── IAM_group_permissions.png
│   │   ├── IAM_user_groups.png
│   │   └── IAM_user_permissions.png
│   └── subtask_4/
│       ├── IAM_policy_simulator.png
│       └── cmd_testing_permissions.png
├── task_4/
│   ├── subtask_1/
│   │   ├── IAM_user_access_to_billing.png
│   │   └── IAM_user_testing_access_to_billing.png
│   ├── subtask_2/
│   │   └── cost_allocation_tags.png
│   ├── subtask_3/
│   │   └── billing_and_cost_management_monthly-total-budget.png
│   ├── subtask_4/
│   │   └── cost_anomaly_detection_monitor.png
│   ├── subtask_5/
│   │   └── cost_explorer.png
│   └── subtask_6/
│       ├── adding_alert_for_cost_100.png
│       └── if_cost_100_then_stop_instances.png
├── task_5/
│   ├── subtask_1/
│   │   └── current_dns_records.png
│   ├── subtask_2/
│   │   └── created_hosted_zone.png
│   ├── subtask_3/
│   │   ├── associated_elastic_ip.png
│   │   └── configured_dns_zone.png
│   ├── subtask_4/
│   │   └── configured_custom_ns.png
│   └── subtask_5/
│       └── cmd_checking_domain_migration.png
└── README.md
```
