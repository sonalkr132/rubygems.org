namespace :api_keys do
  desc "Migrate user api keys to ApiKey model"
  task migrate: :environment do
    users = User.all

    total = users.count
    i = 0
    puts "Total: #{total}"
    users.find_each do |user|
      hashed_key = Digest::SHA256.hexdigest(user.api_key)
      scopes_hash = Gemcutter::API_SCOPES.index_with { true }

      api_key = user.api_keys.create(scopes_hash.merge(hashed_key: hashed_key, name: "legacy-key"))
      puts "Count not create new api key: #{api_key.errors.full_messages}, user: #{user.handler}" unless api_key.persisted?

      i += 1
      print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
    end
    puts
    puts "Done."
  end
end
