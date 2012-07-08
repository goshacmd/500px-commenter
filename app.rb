require './auth'
require './commenter'

access_token = get_access_token

# Get fresh photo ids.
fresh_photos = MultiJson.decode(access_token.get('/v1/photos.json').body)['photos']
fresh_photo_ids = fresh_photos.map { |photo| photo['id'] }

commenter = Commenter.new access_token
commenter.comment_random_and_like_on_set fresh_photo_ids
