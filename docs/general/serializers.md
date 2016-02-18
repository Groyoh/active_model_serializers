[Back to Guides](../README.md)

# Serializers

Given a serializer class:

```ruby
class SomeSerializer < ActiveModel::Serializer
end
```

The following methods may be defined in it:

### Attributes

To define attributes on a serializer, you may use `::attribute` or `::attributes`. For most of the adapter, the
attribute defined this way will be rendered as a property of the JSON object. When using the `:json_api` adapter, these
attributes will be in the `attributes` object.

In the following subsection, we assume that we have a `Post(id: Integer, title: String, published: Boolean)` class and a
`Post.new(id: 1, title: "AMS is awesome", published: true)` instance.

#### ::attribute

The `::attribute` method takes the attribute's name as first argument and an optional hash as second argument.

##### Default behavior

By default, the serializer will call `#read_attribute_for_serialization(attribute_name)` on the object to serialize and
the returned value will be used as the attribute value value.

``` ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title
  attribute :published
end
```

Examples:

* With the `:attributes` adapter:

``` json
{
  "title": "AMS is awesome",
  "published": true
}
```

* With the `:json_api` adapter:

``` json
{
  "id": "1",
  "type": "posts",
  "attributes": {
    "title": "AMS is awesome",
    "published": true
  }
}
```

##### Using different JSON key

To specify that the attribute should be rendered using a different JSON key, you can use the `key`:

``` ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title, key: :headline
  attribute :published
end
```

Examples:

* With the `:attributes` adapter:

``` json
{
  "headline": "AMS is awesome",
  "published": true
}
```

* With the `:json_api` adapter:

``` json
{
  "id": "1",
  "type": "posts",
  "attributes": {
    "headline": "AMS is awesome",
    "published": true
  }
}
```

##### Overriding an attribute value

Any attribute value can be overriden by:

* Passing a block to the `attribute` method call.

``` ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title { object.title.upcase }
  attribute :published
end
```

When passing a block, the block will be `instance_eval` in the serializer instance and the block return value
will be used as the attribute value.

* Defining an instance method with the same name as the attribute's name.

``` ruby
class EvenPostSerializer < ActiveModel::Serializer
  attribute :title
  attribute :published

  def title
    object.title.upcase
  end
end
```

Examples:

* With the `:attributes` adapter:

``` json
{
  "title": "AMS IS AWESOME",
  "published": true
}
```

* With the `:json_api` adapter:

``` json
{
  "id": "1",
  "type": "posts",
  "attributes": {
    "title": "AMS IS AWESOME",
    "published": true
  }
}
```

##### Conditional attributes

You can specify that an attribute should be serialized under certain condition using an `if` or `unless` option.

``` ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title, if: :even?
  attribute :published, unless: 'even?'

  def even?
    object.id.even?
  end
end
```

* With the `:attributes` adapter:

``` json
{
  "published": true
}
```

* With the `:json_api` adapter:

``` json
{
  "id": "1",
  "type": "posts",
  "attributes": {
    "published": true
  }
}
```

#### ::attributes

##### Default behavior

By default, `::attributes` works the same way as the `::attribute` method except that it takes
an undefined number of attributes' name as parameters.

``` ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title, :published
end
```

Examples:

* With the `:attributes` adapter:

``` json
{
  "title": "AMS is awesome",
  "published": true
}
```

* With the `:json_api` adapter:

``` json
{
  "id": "1",
  "type": "posts",
  "attributes": {
    "title": "AMS is awesome",
    "published": true
  }
}
```

##### Overriding an attribute value

When using `::attributes`, the only way to override an attribute is to define an instance method
on the serializer which has the same name as the attribute you want to override.

``` ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title, :published

  def title
    object.title.upcase
  end
end
```

Examples:

* With the `:attributes` adapter:

``` json
{
  "title": "AMS IS AWESOME",
  "published": true
}
```

* With the `:json_api` adapter:

``` json
{
  "id": "1",
  "type": "posts",
  "attributes": {
    "title": "AMS IS AWESOME",
    "published": true
  }
}
```

### Associations

#### ::has_one

e.g.

```ruby
has_one :bio
has_one :blog, key: :site
has_one :maker, virtual_value: { id: 1 }
```

#### ::has_many

e.g.

```ruby
has_many :comments
has_many :comments, key: :reviews
has_many :comments, serializer: CommentPreviewSerializer
has_many :reviews, virtual_value: [{ id: 1 }, { id: 2 }]
has_many :comments, key: :last_comments do
  last(1)
end
```

#### ::belongs_to

e.g.

```ruby
belongs_to :author, serializer: AuthorPreviewSerializer
belongs_to :author, key: :writer
belongs_to :post
belongs_to :blog
def blog
  Blog.new(id: 999, name: 'Custom blog')
end
```

### Caching

#### ::cache

e.g.

```ruby
cache key: 'post', expires_in: 0.1, skip_digest: true
cache expires_in: 1.day, skip_digest: true
cache key: 'writer', skip_digest: true
cache only: [:name], skip_digest: true
cache except: [:content], skip_digest: true
cache key: 'blog'
cache only: [:id]
```

#### #cache_key

e.g.

```ruby
# Uses a custom non-time-based cache key
def cache_key
  "#{self.class.name.downcase}/#{self.id}"
end
```

### Other

#### ::type

e.g.

```ruby
class UserProfileSerializer < ActiveModel::Serializer
  type 'profile'
end
```

#### ::link

e.g.

```ruby
link :other, 'https://example.com/resource'
link :self do
 href "https://example.com/link_author/#{object.id}"
end
```

#### #object

The object being serialized.

#### #root

PR please :)

#### #scope

PR please :)

#### #read_attribute_for_serialization(key)

The serialized value for a given key. e.g. `read_attribute_for_serialization(:title) #=> 'Hello World'`

#### #links

PR please :)

#### #json_key

PR please :)

## Examples

Given two models, a `Post(title: string, body: text)` and a
`Comment(name: string, body: text, post_id: integer)`, you will have two
serializers:

```ruby
class PostSerializer < ActiveModel::Serializer
  cache key: 'posts', expires_in: 3.hours
  attributes :title, :body

  has_many :comments
end
```

and

```ruby
class CommentSerializer < ActiveModel::Serializer
  attributes :name, :body

  belongs_to :post
end
```

Generally speaking, you, as a user of ActiveModelSerializers, will write (or generate) these
serializer classes.

## More Info

For more information, see [the Serializer class on GitHub](https://github.com/rails-api/active_model_serializers/blob/master/lib/active_model/serializer.rb)

## Overriding association methods

To override an association, call `has_many`, `has_one` or `belongs_to` with a block:

```ruby
class PostSerializer < ActiveModel::Serializer
  has_many :comments do
    object.comments.active
  end
end
```

## Overriding attribute methods

To override an attribute, call `attribute` with a block:

```ruby
class PostSerializer < ActiveModel::Serializer
  attribute :body do
    object.body.downcase
  end
end
```
