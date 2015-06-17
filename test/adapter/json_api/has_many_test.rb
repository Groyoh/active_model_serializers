require 'test_helper'

module ActiveModel
  class Serializer
    class Adapter
      class JsonApi
        class HasManyTest < Minitest::Test
          def setup
            ActionController::Base.cache_store.clear
            @author = Author.new(id: 1, name: 'Steve K.')
            @author.posts = []
            @author.bio = nil
            @post = Post.new(id: 1, title: 'New Post', body: 'Body')
            @post_without_comments = Post.new(id: 2, title: 'Second Post', body: 'Second')
            @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @first_comment.author = nil
            @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
            @second_comment.author = nil
            @post.comments = [@first_comment, @second_comment]
            @post_without_comments.comments = []
            @first_comment.post = @post
            @second_comment.post = @post
            @post.author = @author
            @post_without_comments.author = nil
            @blog = Blog.new(id: 1, name: "My Blog!!")
            @blog.writer = @author
            @blog.articles = [@post]
            @post.blog = @blog
            @post_without_comments.blog = nil

            @serializer = PostSerializer.new(@post)
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer)
            ActionController::Base.cache_store.clear
          end

          def test_includes_comment_ids
            expected = { data: [ { type: "comments", id: "1" }, { type: "comments", id: "2" } ] }
            assert_equal(expected, @adapter.serializable_hash[:data][:relationships][:comments])
          end

          def test_includes_empty_comments_linkage
            @post.comments = []
            expected = { data: [] }

            assert_equal(expected, @adapter.serializable_hash[:data][:relationships][:comments])
          end

          def test_exclude_blank_linkage_option_set_to_true
            @post.comments = []
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, exclude_blank_linkage: true)

            refute @adapter.serializable_hash[:data][:relationships].key?(:comments)
          end

          def test_exclude_blank_linkage_config
            config = ActiveModel::Serializer::Adapter::JsonApi.config
            default_options = config.default_options
            config.default_options = { exclude_blank_linkage: true }

            @post.comments = []
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, include: 'bio,posts')

            refute @adapter.serializable_hash[:data][:relationships].key?(:comments)

            config.default_options = default_options
          end

          def test_includes_linked_comments
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, include: 'comments')
            expected = Set.new([{
              id: "1",
              type: "comments",
              attributes: {
                body: 'ZOMG A COMMENT'
              },
              relationships: {
                post: { data: { type: "posts", id: "1" } },
                author: { data: nil }
              }
            }, {
              id: "2",
              type: "comments",
              attributes: {
                body: 'ZOMG ANOTHER COMMENT'
              },
              relationships: {
                post: { data: { type: "posts", id: "1" } },
                author: { data: nil }
              }
            }])
            assert_equal expected, @adapter.serializable_hash[:included]
          end

          def test_limit_fields_of_linked_comments
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, include: 'comments', fields: {comment: [:id]})
            expected = Set.new([{
              id: "1",
              type: "comments",
              relationships: {
                post: { data: { type: "posts", id: "1" } },
                author: { data: nil }
              }
            }, {
              id: "2",
              type: "comments",
              relationships: {
                post: { data: { type: "posts", id: "1" } },
                author: { data: nil }
              }
            }])
            assert_equal expected, @adapter.serializable_hash[:included]
          end

          def test_no_include_linked_if_comments_is_empty
            serializer = PostSerializer.new(@post_without_comments)
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer)

            assert_nil adapter.serializable_hash[:linked]
          end

          def test_include_type_for_association_when_different_than_name
            serializer = BlogSerializer.new(@blog)
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer)
            actual = adapter.serializable_hash[:data][:relationships][:articles]
            expected = {
              data: [{
                type: "posts",
                id: "1"
              }]
            }
            assert_equal expected, actual
          end
        end
      end
    end
  end
end
