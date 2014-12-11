#encoding=utf-8

require 'sinatra'
require 'data_mapper'
require 'rest_client'
require 'date'

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
end

#소식알림판------------------
class Post
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :body, Text, :length => 10000000
  property :image_src, String, :length => 10000000
  property :created_at, DateTime
  property :count, Integer
end

class Budget
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :body, Text, :length => 10000000
  property :image_src, String, :length => 10000000
  property :created_at, DateTime
  property :count, Integer
end

class Ncomment
  include DataMapper::Resource
  property :id, Serial
  property :content, Text
  property :user_id, Integer
  property :post_id, Integer
end

class Bcomment
  include DataMapper::Resource
  property :id, Serial
  property :content, Text
  property :user_id, Integer
  property :post_id, Integer
end

DataMapper.finalize
User.auto_upgrade!
Post.auto_upgrade!
Budget.auto_upgrade!
Ncomment.auto_upgrade!
Bcomment.auto_upgrade!
#DataMapper.auto_migrate!

before do
  @user = User.first(:user_email => session[:email])
  @email_name =session[:email]
  @posts = Post.all
  @budgets = Budget.all
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

#잡담게시판
get '/chat' do
  erb :chat
end

#로그인
get '/login' do
  erb :login
end

#404 에러
not_found do
  "404 The page you were looking for doesn't exist. You may have mistyped the address or the page may have moved."
end

#로그인 프로세스
post '/login_process' do
  @comment = ""
  database_user = User.first(:user_email => params[:user_email])

  md5_user_password = Digest::MD5.hexdigest(params[:user_password])


  if !database_user.nil?

    if database_user.user_password == md5_user_password
      session[:email] = params[:user_email]
    end
  end
  redirect '/'
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

  redirect '/'
end

#관리자, 유저삭제
['/admin', "/user_delete/*"].each do |path|
  before path do
    user = User.first(:user_email => session[:email])
    if (user.nil?) or (user.admin != true)
      redirect '/'
    end
  end
end

#관리자 페이지
get '/admin' do
  @users = User.all
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

get '/budget_detail/:id' do
  @budget = Budget.first(:id => params[:id])
  @bcomments = Bcomment.all(:post_id => params[:id])
  erb :budget_detail
end

#일상알림판 댓글 작성
post '/write_notice_comment' do
  p = Ncomment.new
  p.content = params[:content]
  p.user_id = User.first(:user_email => session[:email]).id
  p.post_id = params[:post_id]
  p.save

  redirect "/notice_detail/#{params[:post_id]}"
end

post '/write_budget_comment' do
  p = Bcomment.new
  p.content = params[:content]
  p.user_id = User.first(:user_email => session[:email]).id
  p.post_id = params[:post_id]
  p.save

  redirect "/budget_detail/#{params[:post_id]}"
end

#일상알림판 글쓰기
post '/add_notice_post' do
# 날짜 입력폼
  p = Post.new
  p.title = params[:post_title]
  p.body = params[:post_body]
  p.image_src = params[:post_image]

  if !p.save
    p.errors
  else
    redirect '/admin'
  end
end

post '/add_budget_post' do
# 날짜 입력폼
  p = Budget.new
  p.title = params[:post_title]
  p.body = params[:post_body]
  p.image_src = params[:post_image]

  if !p.save
    p.errors
  else
    redirect '/admin'
  end
end

#런칭시 꼭 삭제 시작---------------------------------
get '/init_database' do #관리자 생성
  n_user = User.new
  n_user.user_email = "admin@admin.com"
  md5_password = Digest::MD5.hexdigest("asdf")
  n_user.user_password = md5_password
  n_user.c_name = "청년허브"
  n_user.n_name = "관리자"
  n_user.admin = true
  n_user.save

  ## Add Post
  1.upto(1) do
    post = Post.new
    post.title = "소식알림 제목입니다"
    post.body = "소식알림 내용입니다"
    post.image_src = "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-xpf1/v/t1.0-1/10434013_235711903291569_927786159788548594_n.png?oh=88c39f78fa3ce632fd60a21ec0383621&oe=55037DC0&__gda__=1426544874_c3e5f71e953a7b43f094c3f99584ebcf"
    post.save
  end

  1.upto(1) do
    post = Budget.new
    post.title = "예산알림 제목입니다"
    post.body = "예산알림 내용입니다"
    post.image_src = "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-xpf1/v/t1.0-1/10434013_235711903291569_927786159788548594_n.png?oh=88c39f78fa3ce632fd60a21ec0383621&oe=55037DC0&__gda__=1426544874_c3e5f71e953a7b43f094c3f99584ebcf"
    post.save
  end

  redirect '/'

end

#유저 데이터베이스 초기화
#런칭시 꼭 주석화하기---------------------------------
get '/destroy_database' do
  User.all.destroy
  Post.all.destroy
  Budget.all.destroy
  session.clear
  redirect '/'
end