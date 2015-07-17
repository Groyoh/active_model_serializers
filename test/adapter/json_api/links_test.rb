require 'test_helper'
module ActiveModel
  class Serializer
    class Adapter
      class JsonApi
        class LinkedTest < Minitest::Test
          def setup
            ActionController::Base.cache_store.clear
            @author = Author.new(id: 1, name: 'Steve K.')
            @post = Post.new(id: 10, title: 'Hello!!', body: 'Hello, world!!')
            @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
            @post.author = @author
            @post.comments = [@first_comment,@second_comment]            
          end

          def test_include_multiple_posts_and_linked_array
            serializer = PostWithLinksSerializer.new @post
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
              serializer
            )
            alt_adapter = ActiveModel::Serializer::Adapter::JsonApi.new(
              serializer,
              include: 'author,author.bio,comments'
            )

            expected = {
              data: [
                {
                  id: "10",
                  type: "posts",
                  attributes: {
                    title: "Hello!!",
                    body: "Hello, world!!"
                  },
                  relationships: {
                    comments: {
                      data: [ { type: "comments", id: '1' }, { type: "comments", id: '2' } ],
                      links: {
                        self: "http://www.example.com/comments/"
                      }
                    },
                    author: {
                      data: { type: "authors", id: "1" },
                      links: {
                        self: "http://www.example.com/posts/10/relationships/author",
                        related: "http://www.example.com/authors/1",
                              
                      }
                    }
                  }
                }
              ]
            }
            assert_equal expected, adapter.serializable_hash
            assert_equal expected, alt_adapter.serializable_hash
          end
        end
      end
    end
  end
end
