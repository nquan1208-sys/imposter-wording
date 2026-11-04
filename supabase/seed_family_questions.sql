-- Original family question pairs, available in the Family tab.
begin;

insert into public.game_categories (id, game_type, slug, sort_order, is_active, is_family_friendly) values
  ('5eed0003-0000-0000-0000-000000000001', 'question', 'family-mealtime', 20, true, true),
  ('5eed0003-0000-0000-0000-000000000002', 'question', 'family-together', 21, true, true),
  ('5eed0003-0000-0000-0000-000000000003', 'question', 'family-imagination', 22, true, true)
on conflict (id) do nothing;

insert into public.game_category_translations (category_id, locale, name, description, status) values
  ('5eed0003-0000-0000-0000-000000000001', 'vi', 'Gia đình · Bữa ăn vui vẻ', 'Sở thích ăn uống gần gũi, trả lời bằng tên món ăn hoặc đồ uống.', 'published'),
  ('5eed0003-0000-0000-0000-000000000002', 'vi', 'Gia đình · Cùng nhau mỗi ngày', 'Hoạt động quen thuộc ở nhà và ngoài trời, không cần kiến thức chuyên môn.', 'published'),
  ('5eed0003-0000-0000-0000-000000000003', 'vi', 'Gia đình · Tưởng tượng ngộ nghĩnh', 'Tình huống tưởng tượng nhẹ nhàng về động vật, màu sắc và đồ vật.', 'published'),
  ('5eed0003-0000-0000-0000-000000000001', 'en', 'Family · Happy Mealtimes', 'Everyday food preferences; answer with a food or drink name.', 'published'),
  ('5eed0003-0000-0000-0000-000000000002', 'en', 'Family · Time Together', 'Familiar indoor and outdoor activities, with no specialist knowledge needed.', 'published'),
  ('5eed0003-0000-0000-0000-000000000003', 'en', 'Family · Silly Imagination', 'Lighthearted imaginary situations about animals, colors and objects.', 'published')
on conflict (category_id, locale) do nothing;

insert into public.question_prompts (id, category_id, difficulty) values
  ('5eed0013-0000-0000-0000-000000000001', '5eed0003-0000-0000-0000-000000000001', 'easy'),
  ('5eed0013-0000-0000-0000-000000000002', '5eed0003-0000-0000-0000-000000000001', 'easy'),
  ('5eed0013-0000-0000-0000-000000000003', '5eed0003-0000-0000-0000-000000000001', 'easy'),
  ('5eed0013-0000-0000-0000-000000000004', '5eed0003-0000-0000-0000-000000000001', 'easy'),
  ('5eed0013-0000-0000-0000-000000000005', '5eed0003-0000-0000-0000-000000000001', 'easy'),
  ('5eed0013-0000-0000-0000-000000000006', '5eed0003-0000-0000-0000-000000000002', 'easy'),
  ('5eed0013-0000-0000-0000-000000000007', '5eed0003-0000-0000-0000-000000000002', 'easy'),
  ('5eed0013-0000-0000-0000-000000000008', '5eed0003-0000-0000-0000-000000000002', 'easy'),
  ('5eed0013-0000-0000-0000-000000000009', '5eed0003-0000-0000-0000-000000000002', 'easy'),
  ('5eed0013-0000-0000-0000-00000000000a', '5eed0003-0000-0000-0000-000000000002', 'easy'),
  ('5eed0013-0000-0000-0000-00000000000b', '5eed0003-0000-0000-0000-000000000003', 'easy'),
  ('5eed0013-0000-0000-0000-00000000000c', '5eed0003-0000-0000-0000-000000000003', 'easy'),
  ('5eed0013-0000-0000-0000-00000000000d', '5eed0003-0000-0000-0000-000000000003', 'easy'),
  ('5eed0013-0000-0000-0000-00000000000e', '5eed0003-0000-0000-0000-000000000003', 'easy'),
  ('5eed0013-0000-0000-0000-00000000000f', '5eed0003-0000-0000-0000-000000000003', 'easy')
on conflict (id) do nothing;

insert into public.question_prompt_translations (prompt_id, locale, civilian_question, imposter_question, status) values
  ('5eed0013-0000-0000-0000-000000000001', 'vi', 'Bạn muốn ăn món gì trong buổi dã ngoại?', 'Bạn muốn ăn món gì khi xem phim ở nhà?', 'published'),
  ('5eed0013-0000-0000-0000-000000000002', 'vi', 'Bạn chọn loại trái cây nào để làm nước ép?', 'Bạn chọn loại trái cây nào để làm kem?', 'published'),
  ('5eed0013-0000-0000-0000-000000000003', 'vi', 'Bạn muốn uống gì sau khi chơi ngoài trời?', 'Bạn muốn uống gì trong bữa sáng?', 'published'),
  ('5eed0013-0000-0000-0000-000000000004', 'vi', 'Bạn muốn thêm nguyên liệu gì vào bánh mì?', 'Bạn muốn thêm nguyên liệu gì lên bánh pizza?', 'published'),
  ('5eed0013-0000-0000-0000-000000000005', 'vi', 'Bạn muốn cùng mọi người làm món tráng miệng gì?', 'Bạn muốn mang món tráng miệng gì đến buổi dã ngoại?', 'published'),
  ('5eed0013-0000-0000-0000-000000000006', 'vi', 'Trời mưa, bạn muốn chơi trò gì trong nhà?', 'Buổi tối, bạn muốn chơi trò gì cùng mọi người?', 'published'),
  ('5eed0013-0000-0000-0000-000000000007', 'vi', 'Bạn muốn làm gì đầu tiên khi đến công viên?', 'Bạn muốn làm gì đầu tiên khi đến bãi biển?', 'published'),
  ('5eed0013-0000-0000-0000-000000000008', 'vi', 'Bạn chọn món đồ gì để chơi trên bãi cát?', 'Bạn chọn món đồ gì để chơi ở công viên?', 'published'),
  ('5eed0013-0000-0000-0000-000000000009', 'vi', 'Bạn muốn cùng mọi người trồng loại cây gì?', 'Bạn muốn trồng loại cây gì trong một chiếc chậu nhỏ?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000a', 'vi', 'Bạn muốn nghe âm thanh gì khi thức dậy?', 'Bạn muốn nghe âm thanh gì trước khi ngủ?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000b', 'vi', 'Nếu con vật có thể nói, bạn muốn trò chuyện với con gì?', 'Nếu con vật có thể dẫn đường, bạn muốn đi khám phá cùng con gì?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000c', 'vi', 'Bạn chọn màu gì để sơn một ngôi nhà trên cây?', 'Bạn chọn màu gì để sơn một con tàu vũ trụ?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000d', 'vi', 'Nếu có đôi cánh, bạn muốn bay đến nơi nào?', 'Nếu có cánh cửa thần kỳ, bạn muốn mở cửa đến nơi nào?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000e', 'vi', 'Bạn muốn con rô-bốt giúp làm việc gì trong nhà?', 'Bạn muốn có phép thuật để làm xong việc gì trong nhà?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000f', 'vi', 'Bạn chọn đồ vật gì để biến thành khổng lồ?', 'Bạn chọn đồ vật gì để thu nhỏ bằng bàn tay?', 'published'),
  ('5eed0013-0000-0000-0000-000000000001', 'en', 'What food would you like to eat on a picnic?', 'What food would you like to eat while watching a movie at home?', 'published'),
  ('5eed0013-0000-0000-0000-000000000002', 'en', 'Which fruit would you choose to make juice?', 'Which fruit would you choose to make ice cream?', 'published'),
  ('5eed0013-0000-0000-0000-000000000003', 'en', 'What would you like to drink after playing outdoors?', 'What would you like to drink with breakfast?', 'published'),
  ('5eed0013-0000-0000-0000-000000000004', 'en', 'What ingredient would you add to a sandwich?', 'What ingredient would you add to a pizza?', 'published'),
  ('5eed0013-0000-0000-0000-000000000005', 'en', 'What dessert would you like to make with everyone?', 'What dessert would you like to bring to a picnic?', 'published'),
  ('5eed0013-0000-0000-0000-000000000006', 'en', 'What game would you like to play indoors on a rainy day?', 'What game would you like to play with everyone in the evening?', 'published'),
  ('5eed0013-0000-0000-0000-000000000007', 'en', 'What would you like to do first at a park?', 'What would you like to do first at a beach?', 'published'),
  ('5eed0013-0000-0000-0000-000000000008', 'en', 'What object would you choose to play with on the sand?', 'What object would you choose to play with at a park?', 'published'),
  ('5eed0013-0000-0000-0000-000000000009', 'en', 'What plant would you like to grow with everyone?', 'What plant would you like to grow in a small pot?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000a', 'en', 'What sound would you like to hear when you wake up?', 'What sound would you like to hear before going to sleep?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000b', 'en', 'If animals could talk, which animal would you chat with?', 'If animals could be guides, which animal would you explore with?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000c', 'en', 'What color would you choose to paint a treehouse?', 'What color would you choose to paint a spaceship?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000d', 'en', 'If you had wings, where would you fly?', 'If you had a magic door, where would you want it to open?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000e', 'en', 'What household chore would you want a robot to help with?', 'What household chore would you want to finish using magic?', 'published'),
  ('5eed0013-0000-0000-0000-00000000000f', 'en', 'What object would you choose to make giant?', 'What object would you choose to shrink to the size of your hand?', 'published')
on conflict (prompt_id, locale) do nothing;

commit;
