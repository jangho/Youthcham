#encoding=utf-8
require 'sinatra'
require 'data_mapper'
require 'thin'
require 'rest_client'
require 'date'
require 'sinatra/flash'
require 'will_paginate'
#require 'will_paginate/data_mapper'
require 'sinatra/reloader' if development?

enable :sessions

#데이터베이스
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/youth.db")

#유저
class User
  include DataMapper::Resource
  property :id, Serial
  property :user_email, String
  #Community_name, Nick_name 약자
  property :c_name, String
  property :n_name, String
  property :user_password, String
  property :created_at, DateTime
  property :admin, Boolean

  validates_uniqueness_of :user_email
  validates_uniqueness_of :n_name
end

#소식알림판------------------
class Post
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :sub_title, String
  property :body, Text, :length => 10000000
  property :image_src, String, :length => 10000000
  property :created_at, DateTime
#  property :count, Integer
end

#예산알림판------------------
class Budget
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :sub_title, String
  property :body, Text, :length => 10000000
  property :image_src, String, :length => 10000000
  property :created_at, DateTime
#  property :count, Integer
end

#커뮤니티소개------------------
class Community
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :url, String
  property :body, Text, :length => 10000000
  property :created_at, DateTime
  property :sub_title, String,  :length => 1000
#  property :type, String
#  property :image_src, String, :length => 10000000
end

#댓글
class Chat
  include DataMapper::Resource
  property :id, Serial
  property :user_id, String
  property :c_id, String
  property :title, String
  property :body, Text, :length => 10000000
  property :image_src, String, :length => 10000000
  property :created_at, DateTime
end

#일상 알림판 코멘트
class Ncomment
  include DataMapper::Resource
  property :id, Serial
  property :content, Text
  property :user_id, Integer
  property :c_id, Integer
  property :post_id, Integer
  property :created_at, DateTime
end

#예산 알림판 코멘트
class Bcomment
  include DataMapper::Resource
  property :id, Serial
  property :content, Text
  property :user_id, Integer
  property :c_id, Integer
  property :post_id, Integer
  property :created_at, DateTime
end

#잡담 게시판 댓글
class Comment
  include DataMapper::Resource
  property :id, Serial
  property :content, Text
  property :user_id, Integer
  property :c_id, Integer
  property :post_id, Integer
  property :created_at, DateTime
end

DataMapper.finalize
User.auto_upgrade!
Post.auto_upgrade!
Budget.auto_upgrade!
Community.auto_upgrade!
Chat.auto_upgrade!
Ncomment.auto_upgrade!
Bcomment.auto_upgrade!
Comment.auto_upgrade!
DataMapper.auto_upgrade!

before do
  @users = User.all
  @user = User.first(:user_email => session[:email])
  @email_name =session[:email]
  @posts = Post.all.reverse
  @budgets = Budget.all.reverse
  @communitys = Community.all.reverse
end

get '/' do
  erb :index
end

#일상 알림판
get '/notice' do
  erb :notice
end

#예산 알림판
get '/budget' do
  erb :budget
end

#커뮤니티 게시판
get '/community' do
  erb :community
end

#모임게시판

get '/day' do
  erb :day
end

#잡담게시판
get '/chat' do
  @chats = Chat.all.reverse
  erb :chat
end

#로그인
get '/login' do
  erb :login
end

get '/add_chat' do
  erb :add_chat
end

get '/add_community' do
  erb :add_community
end

get '/add_notice' do
  erb :add_notice
end

get '/add_budget' do
  erb :add_budget
end


#404 에러
not_found do
  "404 The page you were looking for doesn't exist. You may have mistyped the address or the page may have moved."
end

error do
  'error'
end

#로그인 프로세스
post '/login_process' do
  @comment = ""
  database_user = User.first(:user_email => params[:user_email])

  md5_user_password = Digest::MD5.hexdigest(params[:user_password])

  if !database_user.nil?
    if database_user.user_password == md5_user_password
      session[:email] = params[:user_email]
      redirect '/'
    end
    redirect '/login'
  end
end

#로그아웃
get '/logout' do
  session.clear
  redirect '/'
end

#회원가입
get '/join' do
  erb :join
end

#회원가입 프로세스
post '/join_process' do
  n_user = User.new

  #새로운 User, new_user 줄임
  n_user.user_email = params[:user_email]
  n_user.c_name = params[:c_name]
  n_user.n_name = params[:n_name]
  n_user.admin = false

  #패스워드 암호화
  md5_password = Digest::MD5.hexdigest(params[:user_password])
  n_user.user_password = md5_password
  n_user.save

  redirect '/login'
end

#관리자, 유저삭제
['/add_notice','/add_budget','/add_community','/admin', "/user_delete/*"].each do |path|
  before path do
    user = User.first(:user_email => session[:email])
    if (user.nil?) or (user.admin != true)
      redirect '/'
    end
  end
end

#유저
['/add_chat','/budget'].each do |path|
  before path do
    user = User.first(:user_email => session[:email])
    if (user.nil?)
      redirect '/'
    end
  end
end


#관리자 페이지
get '/admin' do
  erb :admin
end

#유저 삭제
get '/user_delete/:user_id' do
  user = User.first(:user_email => session[:email])
  if (!user.nil?) and (user.admin == true)
    user = User.first(:id => params[:user_id])
    user.destroy
    redirect '/admin'
  else
    redirect '/'
  end
end

#비밀번호 찾기
get '/forgot_password' do
  erb :forgot_password
end

#새 비밀번호 전송
post '/send_new_password_email' do
  u = User.first(:user_email => params[:email_recv])
  if u.nil?
    "해당 유저가 없습니다"
  else
    temp_pwd=('a'..'z').to_a.sample(10).join
    u.user_password = Digest::MD5.hexdigest(temp_pwd)
    u.save
    RestClient.post "https://api:key-5035f6e0c7e69fd300aa6484355d8bc1"\
"@api.mailgun.net/v2/sandbox4df465cb81e746e0a53acb9f266721e1.mailgun.org/messages",
                    :from => "no-reply<no-reply@youthcham.kr>",
                    :to => u.user_email,
                    :subject => "새로 발급한 비밀번호",
                    :text => "새비밀번호는 #{ temp_pwd } 입니다"
    erb :login
  end
end

#일상알림판 글보기
get '/notice_detail/:id' do
  @post = Post.first(:id => params[:id])
  @ncomments = Ncomment.all(:post_id => params[:id])
  erb :notice_detail
end

#예산알림판 글보기
get '/budget_detail/:id' do
  @budget = Budget.first(:id => params[:id])
  @bcomments = Bcomment.all(:post_id => params[:id])
  erb :budget_detail
end

#커뮤니티 글보기
get '/community_detail/:id' do
  @community = Community.first(:id => params[:id])
  erb :community_detail
end

#잡담 글보기
get '/chat_detail/:id' do
  @chat = Chat.first(:id => params[:id])
  @comments = Comment.all(:post_id => params[:id])
  erb :chat_detail
end

#일상알림판 댓글 작성
post '/write_notice_comment' do
  p = Ncomment.new
  p.content = params[:content]
  p.user_id = User.first(:user_email => session[:email]).id
  p.post_id = params[:post_id]
  p.created_at = params[:created_at]
  p.save

  redirect "/notice_detail/#{params[:post_id]}"
end

#예산알림판 댓글 작성
post '/write_budget_comment' do
  p = Bcomment.new
  p.content = params[:content]
  p.user_id = User.first(:user_email => session[:email]).id
  p.post_id = params[:post_id]
  p.created_at = params[:created_at]
  p.save

  redirect "/budget_detail/#{params[:post_id]}"
end

#잡답 댓글 작성
post '/write_chat_comment' do
  p = Comment.new
  p.content = params[:content]
  p.user_id = User.first(:user_email => session[:email]).id
  p.post_id = params[:post_id]
  p.created_at = params[:created_at]
  p.save

  redirect "/chat_detail/#{params[:post_id]}"
end

#일상알림판 글쓰기
post '/add_notice_post' do
  p = Post.new
  p.title = params[:post_title]
  p.sub_title = params[:post_sub_title]
  p.body = params[:post_body]
  p.image_src = params[:post_image]

  if !p.save
    p.errors
  else
    redirect '/notice'
  end
end

#예산알림판 글쓰기
post '/add_budget_post' do
  p = Budget.new
  p.title = params[:post_title]
  p.sub_title = params[:post_sub_title]
  p.body = params[:post_body]
  p.image_src = params[:post_image]

  if !p.save
    p.errors
  else
    redirect '/budget'
  end
end

#커뮤니티 등록
post '/add_community_post' do
  p = Community.new
  p.title = params[:post_title]
#  p.sub_title = params[:post_sub_title]
  p.url = params[:post_url]
#  p.type = params[:post_type]
  p.body = params[:post_body]
#  p.image_src = params[:post_image]

  if !p.save
    p.errors
  else
    redirect '/add_community'
  end
end

#잡담 등록
post '/add_chat_post' do
  p = Chat.new
  p.title = params[:post_title]
  p.c_id = User.first(:user_email => session[:email]).c_name
  p.user_id = User.first(:user_email => session[:email]).n_name
  p.body = params[:post_body]
  p.image_src = params[:post_image]

  if !p.save
    p.errors
  else
    redirect '/chat'
  end
end

#런칭시 꼭 삭제 시작---------------------------------
get '/init_admin_jhc' do
  #관리자 생성
  n_user = User.new
  n_user.user_email = "nextdinos@gmail.com"
  md5_password = Digest::MD5.hexdigest("sukje1")
  n_user.user_password = md5_password
  n_user.c_name = "청년참"
  n_user.n_name = "매니저"
  n_user.admin = true
  n_user.save
  redirect '/'
end

get '/init_database_jhc' do
  #관리자 생성
  n_user = User.new
  n_user.user_email = "cham@youthhub.kr"
  md5_password = Digest::MD5.hexdigest("youthhub2015")
  n_user.user_password = md5_password
  n_user.c_name = "청년허브"
  n_user.n_name = "청년참"
  n_user.admin = true
  n_user.save

=begin
  # 알립니다 임시생성
  1.upto(1) do
    post = Post.new
    post.title = "소식알림 제목입니다"
    post.body = "소식알림 내용입니다"
    post.image_src = "https://scontent-a.xx.fbcdn.net/hphotos-xap1/v/t1.0-9/72820_398308553610666_1901296869_n.png?oh=4663b4271aa8e8c581883ef40252faa3&oe=55337BE5"
    post.save
  end

  # 예산알림 임시생성
  1.upto(1) do
    post = Budget.new
    post.title = "예산알림 제목입니다"
    post.body = "예산알림 내용입니다"
    post.image_src = "https://scontent-a.xx.fbcdn.net/hphotos-xap1/v/t1.0-9/72820_398308553610666_1901296869_n.png?oh=4663b4271aa8e8c581883ef40252faa3&oe=55337BE5"
    post.save
  end

  1.upto(1) do
    post = Community.new
    post.title = "청년허브"
    post.sub_title = "청년이 동료를 만나 서로 협력하고 즐겁게 일하는 사회를 만드는 것, 청년허브의 미션입니다."
    post.body = "스스로 움직이는 청년들이 필요로 하는 것을 파악하고 서로 접점을 만들어 나가며 자원을 연결하려 합니다. 청년문제에서 출발하지만 청년을 통해 생명력 넘치는 사회가 만들어지길 청년허브는 꿈꿉니다."
    post.url = "http://youthhub.kr"
    post.type = "청년허브"
    post.image_src = "https://scontent-a.xx.fbcdn.net/hphotos-xap1/v/t1.0-9/72820_398308553610666_1901296869_n.png?oh=4663b4271aa8e8c581883ef40252faa3&oe=55337BE5"
    post.save
  end
=end

  redirect '/'

end

#유저 데이터베이스 초기화
#런칭시 꼭 주석화하기---------------------------------
get '/destroy_database_jhc' do
#   User.all.destroy
#  Post.all.destroy
#  Budget.all.destroy
#  Community.all.destroy
#  Chat.all.destroy
#  session.clear
  redirect '/'
end