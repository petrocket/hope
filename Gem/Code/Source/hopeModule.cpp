
#include <AzCore/Memory/SystemAllocator.h>
#include <AzCore/Module/Module.h>

#include <hopeSystemComponent.h>

namespace hope
{
    class hopeModule
        : public AZ::Module
    {
    public:
        AZ_RTTI(hopeModule, "{31C554A1-09EC-4396-99E1-4B36D7634BB9}", AZ::Module);
        AZ_CLASS_ALLOCATOR(hopeModule, AZ::SystemAllocator, 0);

        hopeModule()
            : AZ::Module()
        {
            // Push results of [MyComponent]::CreateDescriptor() into m_descriptors here.
            m_descriptors.insert(m_descriptors.end(), {
                hopeSystemComponent::CreateDescriptor(),
            });
        }

        /**
         * Add required SystemComponents to the SystemEntity.
         */
        AZ::ComponentTypeList GetRequiredSystemComponents() const override
        {
            return AZ::ComponentTypeList{
                azrtti_typeid<hopeSystemComponent>(),
            };
        }
    };
}

// DO NOT MODIFY THIS LINE UNLESS YOU RENAME THE GEM
// The first parameter should be GemName_GemIdLower
// The second should be the fully qualified name of the class above
AZ_DECLARE_MODULE_CLASS(hope_ffd828da88a24c85aeb6d330a010135c, hope::hopeModule)
