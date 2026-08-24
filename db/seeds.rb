require_relative '../lib/convos'

u = User.create! username: 'raul', password: 'yes'
c2 = Comment.create! body: 'comment2', user: u, status: 'published'
c1 = Comment.create! thread_id: 'thread1', body: 'comment1', user: u, successor: c2, status: 'published'
