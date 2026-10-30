post = Post.find_or_create_by!(title: "Анхны пост") do |p|
  p.content = "Rails REST API-ийн жишээ пост"
end
post.comments.find_or_create_by!(comment: "Анхны сэтгэгдэл")
