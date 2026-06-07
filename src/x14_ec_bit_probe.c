#include <linux/acpi.h>
#include <linux/init.h>
#include <linux/module.h>

#define PFX "X14ECB "

static int offset = -1;
module_param(offset, int, 0444);
MODULE_PARM_DESC(offset, "EC byte offset to modify; negative means read-only");

static int mask;
module_param(mask, int, 0444);
MODULE_PARM_DESC(mask, "Bit mask to modify");

static int value;
module_param(value, int, 0444);
MODULE_PARM_DESC(value, "Masked value to write");

static int __init x14_ec_bit_probe_init(void)
{
	u8 before;
	u8 after;
	int ret;

	if (offset < 0) {
		pr_info(PFX "read-only load; set offset/mask/value to modify one EC byte\n");
		return 0;
	}

	if (offset > 0xff || mask < 0 || mask > 0xff || value < 0 || value > 0xff) {
		pr_info(PFX "invalid params offset=%d mask=0x%x value=0x%x\n",
			offset, mask, value);
		return -EINVAL;
	}

	ret = ec_read((u8)offset, &before);
	if (ret) {
		pr_info(PFX "read offset 0x%02x failed ret=%d\n", offset, ret);
		return ret;
	}

	after = (before & ~(u8)mask) | ((u8)value & (u8)mask);
	pr_info(PFX "offset=0x%02x before=0x%02x mask=0x%02x value=0x%02x after=0x%02x\n",
		offset, before, mask, value, after);

	if (after != before) {
		ret = ec_write((u8)offset, after);
		if (ret) {
			pr_info(PFX "write offset 0x%02x failed ret=%d\n", offset, ret);
			return ret;
		}
	}

	ret = ec_read((u8)offset, &before);
	if (ret) {
		pr_info(PFX "verify read offset 0x%02x failed ret=%d\n", offset, ret);
		return ret;
	}

	pr_info(PFX "verify offset=0x%02x now=0x%02x\n", offset, before);
	return 0;
}

static void __exit x14_ec_bit_probe_exit(void)
{
	pr_info(PFX "exit\n");
}

module_init(x14_ec_bit_probe_init);
module_exit(x14_ec_bit_probe_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("ThinkPad X14 Gen1 targeted EC bit probe");
