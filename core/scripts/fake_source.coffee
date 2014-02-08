class FakeSource
  @buildItemFromTweet: (tweet)->
    item = 
      # principal
      serv: 'twitter'
      id: tweet.id_str
      # core
      title: tweet.user.name
      URL: "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
      text: tweet.text
      time: new Date(tweet.created_at).toDateString()
      author_id: tweet.user.id_str
      author_name: tweet.user.screen_name
      author_url: "https://twitter.com/#{tweet.user.screen_name}"
      # extend
      previous_item_id: tweet.in_reply_to_status_id_str
      next_item_id: ''
      recipient_id: tweet.in_reply_to_user_id_str
      recipient_name: tweet.in_reply_to_screen_name
      feature_pic_url: tweet.user.profile_image_url
      source: tweet.source
      entities: tweet.entities
      deletable: false
      repostable: true
      favorited: tweet.favorited
      reposted: tweet.retweeted
      original_id: ''
      reposter_id: ''
      reposter_name: ''
      has_comments: (tweet.in_reply_to_status_id_str != null)
      media_type: 'none'
      media: []

    return item

  @items = []
  for t in fake_home_timeline
    @items.push(@buildItemFromTweet(t))

  @item = 
    # principal
    serv: 'twitter'
    id: "272614791342862336"
    # core
    title: "weimin"
    URL: "https://twitter.com/dr_filter_ch/status/91017586954862592"
    text: "18. MBP好暖和！"
    time: 1310535258000
    author_id: "17481583"
    author_name: "dr_filter_ch"
    author_url: "https://twitter.com/dr_filter_ch"
    # extend
    minor_title: "dr_filter_ch"
    previous_item_id: "91016252461547520"
    next_item_id: ''
    recipient_id: ''
    recipient_name: ''
    feature_pic_url: "http://a0.twimg.com/sticky/default_profile_images/default_profile_1_normal.png"
    source: ["hotot", "http://hotot.org"]
    entities: {
      hashtags: [],
      urls: [],
      user_mentions: [
        {
          "screen_name": "shellex",
          "name": "壳酱",
          "id": '17481583',
          "indices": [0, 8]
        }
      ]
    },
    deletable: false
    repostable: true
    favorited: false
    reposted: false
    original_id: ''
    reposter_id: ''
    reposter_name: ''
    media_type: 'none'
    media: []

  @getSingleItem: ->
    xx = {}
    angular.extend(xx, @item)
    return xx

  @getItems: (start, end)->
    start = start or 0
    shuffle = (items) ->
      for i in [0...items.length]
        a = parseInt(Math.random()*10000)%items.length
        b = parseInt(Math.random()*10000)%items.length
        t = items[a]
        items[a] = items[b]
        items[b] = t
    xx = []
    for it in @items
      xxx = {}
      angular.extend(xxx, it)
      xx.push(xxx)
    return xx.slice(start, end)


  
root = exports ? this
root.FakeSource = FakeSource

