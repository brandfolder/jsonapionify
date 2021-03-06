module JSONAPIonify::Structure
  module Objects
    class Relationship < Base
      define_order *%i{data meta links}

      # A "relationship object" MUST contain at least one of the following:
      must_contain_one_of! :links, # A links object.
                           :data, # Resource linkage.
                           :meta # A meta object that contains non-standard meta-information about the relationship.

      implements :links, as: Maps::Links
      implements :meta, as: Meta

      collects_or_implements(
        :data,
        collects:   Collections::ResourceIdentifiers,
        implements: ResourceIdentifier,
        allow_nil:  true
      )
    end
  end
end
