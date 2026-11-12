namespace :tags do
  desc "読み(reading)が空のタグに読み仮名を自動生成して埋める（何度実行しても安全）"
  task backfill_reading: :environment do
    scope = ActsAsTaggableOn::Tag.where(reading: [ nil, "" ])
    total = scope.count

    # 保存時のコールバック（TagReading）が読みを生成する
    scope.find_each(&:save!)

    puts "読みを補ったタグ: #{total}件"
  end
end
