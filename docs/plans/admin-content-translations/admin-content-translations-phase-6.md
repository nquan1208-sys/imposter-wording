# Phase 6 — Xác minh local và quy trình chuyển đổi

Ngày thực hiện: 2026-10-24.

**Hoàn tất backup/restore, kiểm thử tự động và tài liệu local; chưa hoàn tất manual UI verification, chưa triển khai cloud.** Phạm vi được chốt là local + tài liệu. Không resume project Dev, không đổi credentials, không triển khai hosting hoặc Flutter. Phase 5 vẫn còn kiểm tra UI; không đánh dấu toàn bộ lộ trình đã triển khai.

## Kết quả local

- Ledger local khớp đủ **14 migrations**, kết thúc ở `20261024093556_admin_content_conflict_errors.sql`. Không reset DB đang dùng, không sửa hoặc replay migration lịch sử trên DB này.
- Admin **57/57 tests**, full typecheck và `build:local` đạt. Vite vẫn cảnh báo chunk admin 511.40 kB lớn hơn 500 kB; chưa tối ưu bundle vì ngoài phạm vi.
- Migration rehearsal **6/6 tests**, gồm replay schema cũ rỗng/có dữ liệu, đối chiếu backfill, rollback blockers và toàn bộ forward migrations. **8 concurrency races** đạt.
- Storage HTTP integration đạt: public visibility đa ngôn ngữ, thay đổi danh mục, cleanup ảnh khi save thất bại, giữ bytes sau xóa và signed URL còn hạn.
- DB lint/advisors local không có warning/error. DB rehearsal và DB restore tạm đều đã được dọn.
- Đã kiểm tra liên kết tương đối của bộ tài liệu và guides/README liên quan; cả tám bảng public trong DBML khớp cột với schema local. `git diff --check` đạt.
- Nội dung local giữ **3 danh mục / 5 bản dịch danh mục, 1 đề từ / 1 bản dịch, 1 đề câu hỏi / 1 bản dịch**, 2 ngôn ngữ và 3 Storage objects. Fixtures Storage đã được cleanup.

### Backup đã kiểm chứng

Backup nằm ngoài Git tại:

```text
~/.local/state/imposter-wording/backups/20261024-171412-phase6/local.dump
~/.local/state/imposter-wording/backups/20261024-171412-phase6/verification.json
```

Thư mục backup được tạo quyền `0700`, dump và manifest `0600`. SHA-256 dump:

```text
a83322155c6d38a4ec73f9276d50038fa54b742101fed925979539a18cda9ed2
```

Đã dùng `pg_dump -Fc` với `supabase_admin`, restore bằng `pg_restore --exit-on-error --no-publications --no-subscriptions` vào DB tạm thuộc container local. Đối chiếu số dòng và MD5 trên JSON toàn bộ từng dòng, sắp xếp ổn định, cho 13 bảng: tám bảng public, `auth.users`, `auth.sessions`, `storage.buckets`, `storage.objects` và `supabase_migrations.schema_migrations`. Kết quả bản restore và DB nguồn khớp trước khi chạy các tests. Dump bao gồm schema/functions/policies; kiểm thử quyền nằm trong rehearsal riêng.

Dump này chứa dữ liệu nhạy cảm Auth; không commit/chia sẻ. Đây là snapshot **sau chuyển đổi local**, không phải backup schema cũ để rollback cloud. DB dump chỉ chứa metadata Storage, **không chứa bytes ảnh**. Không dùng nó thay backup đầy đủ của môi trường đích.

### Kiểm tra UI còn lại

Chrome native đọc được danh sách danh mục và form tạo mới. DevTools đã mở qua menu, điều khiển Width xác nhận `390`; tuy nhiên click/focus có lúc đi sang Network filter, ảnh chụp có lúc trắng hoặc phóng lớn bất thường. Không tạo/lưu nội dung UI thử nghiệm trong phiên này, không coi capture là bằng chứng layout đạt. Đã rời form chưa lưu, tắt responsive/DevTools và trở về danh sách danh mục.

Các mục sau **chưa xác minh trực tiếp**, phải hoàn tất trước cutover:

- Layout 390px của dashboard, danh mục, editor từ và editor câu hỏi; menu, cuộn, nút lưu và hộp xác nhận phải truy cập được.
- Vòng đời danh mục bằng bàn phím: tạo, thêm bản dịch, publish/archive, bật/tắt, transfer và purge với fixtures riêng.
- Upload/save thất bại trong editor từ: giữ draft, hiển thị lỗi, retry và cleanup đúng ảnh mới.
- Smoke đăng nhập lại với admin hợp lệ và chặn user không có quyền trên đúng môi trường đích.

Các hành vi dữ liệu đã có automated coverage; phần UI chưa hoàn tất không được thay bằng kết quả unit/SQL tests.

## Chạy lại kiểm thử

Từ repo root, với local stack đang chạy:

```bash
rtk proxy python3 supabase/tests/content_translations.py
rtk proxy supabase db lint --local --schema public,private --level warning --fail-on warning
rtk proxy supabase db advisors --local --type all --level warn --fail-on warn
rtk proxy supabase migration list --local
```

Rehearsal tự tạo bản sao DB, chạy các SQL suites và concurrency, rồi dọn bản sao. Nó không reset DB nguồn. Audit `supabase/scripts/audit_content_translations.sql` và suite audit Phase 1 dành cho **schema cũ**; không chạy trực tiếp trên DB local đã bỏ các cột cũ. Chạy audit trên bản sao legacy trước migration.

Từ `admin/`:

```bash
rtk proxy yarn test
rtk proxy yarn build:local
rtk proxy yarn test:storage
```

Storage suite tạo fixtures riêng rồi cleanup; không chạy nó khi đang chụp manifest backup cần trạng thái ổn định.

### Tạo và thử restore backup DB local

Từ repo root, khi không có thao tác ghi hoặc tests khác:

```bash
umask 077
backup_dir="$HOME/.local/state/imposter-wording/backups/$(date +%Y%m%d-%H%M%S)"
rtk proxy mkdir -p "$backup_dir"
rtk proxy docker exec supabase_db_imposter-wording pg_dump -U supabase_admin -d postgres -Fc > "$backup_dir/local.dump"
rtk proxy shasum -a 256 "$backup_dir/local.dump"
rtk proxy docker exec supabase_db_imposter-wording createdb -U supabase_admin -O postgres ct_restore_check
rtk proxy docker exec -i supabase_db_imposter-wording pg_restore -U supabase_admin -d ct_restore_check --exit-on-error --no-publications --no-subscriptions < "$backup_dir/local.dump"
```

Dừng khi bất kỳ lệnh nào lỗi. Nếu `ct_restore_check` đã tồn tại, không ghi đè; chọn tên DB tạm mới và dùng nhất quán. Đối chiếu 13 bảng đã liệt kê bằng câu SQL sau cho từng bảng, trên cả `postgres` và `ct_restore_check`, rồi so sánh output:

```sql
-- Thay public.game_categories bằng từng tên bảng trong danh sách kiểm tra.
select count(*) as rows,
       md5(coalesce(string_agg(row_data, E'\n' order by row_data), '')) as digest
from (select to_jsonb(t)::text as row_data from public.game_categories t) s;
```

Chạy SQL bằng role `supabase_admin`, không xuất nội dung từng dòng vào báo cáo. Sau khi đối chiếu, chỉ xóa DB tạm vừa tạo:

```bash
rtk proxy docker exec supabase_db_imposter-wording dropdb -U supabase_admin --force ct_restore_check
```

## Quy trình cutover Dev/cloud — chưa thực hiện

Dev `imposter-word` (`pxycsjwjakzehcuygngv`) được inventory xác nhận INACTIVE khi lập kế hoạch. Chưa có hosting admin hoặc production target được cấu hình. Không dùng kết quả local làm bằng chứng dữ liệu cloud an toàn.

1. Hoàn tất các kiểm tra UI còn lại. Xác định đúng project, consumers và artifact admin cũ để phục hồi; resume Dev chỉ khi triển khai cloud được yêu cầu. Kiểm tra CLI `--help`, migration ledger đích và `db push --linked --dry-run`. Không repair ledger để che migration lệch.
2. Backup bản sao đích để rehearsal: schema, data, roles cần thiết, migration history, custom Auth/Storage policies và bytes ảnh riêng. Kiểm tra restore trên môi trường cô lập trước khi cutover. Với DB legacy, chạy audit Phase 1 và xử lý blockers/dependencies chưa có trong repo; chạy pending migrations trên bản sao và đối chiếu ID, nội dung, metadata, trạng thái, slug mapping, locale và ảnh.
3. Chuẩn bị `yarn build:development` trỏ đúng project, giữ artifact admin cũ ngoài repo. Chọn cửa sổ bảo trì. Tạm dừng admin; ghi lại danh sách và trạng thái `admin_users`, đặt admin đang active thành inactive để chặn ghi ở DB qua các phiên/token cũ. Đợi giao dịch ghi đang chạy kết thúc; đóng các tab cũ. Không chỉ dựa vào việc ẩn UI hoặc đăng xuất browser. Chặn các writer đặc quyền bên ngoài nếu audit phát hiện.
4. Khi không còn ghi, tạo **backup cutover mới** và kiểm tra checksum/khả năng restore, giữ snapshot trạng thái admin trước bảo trì riêng. Backup bytes Storage phải cùng cửa sổ ổn định; DB dump không chứa bytes. Không bắt đầu migration nếu backup hoặc rehearsal chưa đạt.
5. Áp dụng đúng pending migrations bằng CLI, không sửa file lịch sử. Migration translations đối chiếu backfill trước khi drop cột trong cùng transaction. Sau đó áp dụng các forward migrations, gồm mã conflict `PT409`. Kiểm tra ledger, schema, grants/RLS và public reads. Chuỗi nhiều migration không phải một transaction chung.
6. Đưa admin mới lên điểm phục vụ đã chọn, kiểm tra URL API đúng target và reload tab. Chỉ mở quyền cho admin kiểm thử trong khi các admin khác vẫn bị khóa; dùng fixtures riêng để smoke đăng nhập, danh sách, save, publish/archive, đọc public cùng locale và ảnh, stale version trả HTTP 409, user bị thu hồi quyền không ghi được. Dọn fixtures trước mở lại ghi.
7. Nếu đạt, khôi phục đúng các trạng thái admin trước bảo trì và yêu cầu mọi người tải lại tab. Ghi thời gian, migration ledger, backup, artifact và kết quả smoke vào báo cáo triển khai; theo dõi lỗi Auth/RPC/Storage và conflict sau mở lại. Chỉ khi đó mới đánh dấu cloud đã triển khai.

### Khi thất bại

- Migration lỗi: transaction của migration đó rollback. Các migration trước trong cùng đợt có thể đã commit; giữ admin khóa, kiểm tra ledger và trạng thái, không chạy tiếp hoặc mở admin cũ vào schema mới.
- Smoke lỗi trước mở lại ghi: giữ bảo trì, khôi phục DB từ backup cutover đã thử restore cùng ledger/policies và artifact admin cũ; phục hồi bytes Storage nếu đã thay đổi. Kiểm tra schema cũ, quyền và dữ liệu trước khi khôi phục các trạng thái admin ban đầu.
- Nếu đã mở lại ghi, không tự restore đè lên dữ liệu mới. Khóa ghi, chụp backup sự cố và đối chiếu phần phát sinh trước khi chọn forward fix hoặc khôi phục có bảo toàn dữ liệu.

Tham khảo chính thức: [Backup và restore bằng CLI](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore), [Database backups và giới hạn Storage](https://supabase.com/docs/guides/platform/backups).

## Tài liệu liên quan

- [Plan chính và trạng thái các phase](./admin-content-translations-plan.md).
- [Phase 5 và manual verification còn lại](./admin-content-translations-phase-5.md).
- [Schema DBML](../../database-schema.dbml).
- [Setup máy mới / schema / quyền hiện tại](../../admin-supabase-new-device-guide.md).
- [Môi trường admin](../../admin-supabase-environment-guide.md).
