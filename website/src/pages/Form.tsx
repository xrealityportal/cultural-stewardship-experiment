import { useState } from "react";
import { useLocation } from "react-router-dom";
import { z } from "zod";
import Layout from "@/components/Layout";
import { toast } from "@/hooks/use-toast";
import { ideasLayers } from "@/data/ideasLayers";

const formSchema = z.object({
  layer: z
    .string()
    .nonempty({ message: "Please choose an Idea Layer" }),
  email: z
    .string()
    .trim()
    .nonempty({ message: "Email is required" })
    .email({ message: "Enter a valid email address" })
    .max(255, { message: "Email must be less than 255 characters" }),
  reason: z
    .string()
    .trim()
    .nonempty({ message: "Please share your reason for joining" })
    .max(1000, { message: "Reason must be less than 1000 characters" }),
});

const Form = () => {
  const location = useLocation();
  const preselectedLayer =
    (location.state as { layer?: string } | null)?.layer ?? "";
  const [values, setValues] = useState({ layer: preselectedLayer, email: "", reason: "" });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const result = formSchema.safeParse(values);
    if (!result.success) {
      const fieldErrors: Record<string, string> = {};
      for (const issue of result.error.issues) {
        const key = issue.path[0] as string;
        if (!fieldErrors[key]) fieldErrors[key] = issue.message;
      }
      setErrors(fieldErrors);
      return;
    }
    setErrors({});
    toast({ title: "Application submitted", description: "Thank you. An Idea Layer member will review your application." });
    setValues({ layer: "", email: "", reason: "" });
  };

  return (
    <Layout>
      <div className="space-y-10 max-w-2xl mx-auto" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
        <h1 className="text-4xl font-bold tracking-tight md:text-4xl">FORM</h1>
        <form onSubmit={handleSubmit} className="space-y-6 text-left" noValidate>
          <div className="space-y-2">
            <label htmlFor="layer" className="block text-base font-bold">
              Chosen Idea Layer:
            </label>
            <select
              id="layer"
              value={values.layer}
              onChange={(e) => setValues({ ...values, layer: e.target.value })}
              className="w-full border-2 border-foreground bg-background px-4 py-2 text-base"
            >
              <option value="">— Select an Idea Layer —</option>
              {ideasLayers.map((l) => (
                <option key={l.n} value={l.title}>
                  {l.title}
                </option>
              ))}
            </select>
            {errors.layer && <p className="text-sm text-destructive">{errors.layer}</p>}
          </div>

          <div className="space-y-2">
            <label htmlFor="reason" className="block text-base font-bold">
              Reason for joining?
            </label>
            <textarea
              id="reason"
              value={values.reason}
              onChange={(e) => setValues({ ...values, reason: e.target.value })}
              maxLength={1000}
              rows={5}
              className="w-full border-2 border-foreground bg-background px-4 py-2 text-base"
            />
            {errors.reason && <p className="text-sm text-destructive">{errors.reason}</p>}
          </div>

          <div className="space-y-2">
            <label htmlFor="email" className="block text-base font-bold">
              Email address:
            </label>
            <input
              id="email"
              type="email"
              value={values.email}
              onChange={(e) => setValues({ ...values, email: e.target.value })}
              maxLength={255}
              placeholder="you@example.com"
              className="w-full border-2 border-foreground bg-background px-4 py-2 text-base"
            />
            {errors.email && <p className="text-sm text-destructive">{errors.email}</p>}
          </div>

          <div className="flex flex-col items-center space-y-4">
            <p className="text-base text-foreground text-center">
              Note: Forms will be reviewed by existing Idea Layer members. Once you have been accepted, you will automatically be assigned a membership role on the forum. To begin participation, login with the same email and you will be able to access chat and vote in your chosen Idea Layer forum page.
            </p>
            <button
              type="submit"
              className="bg-foreground text-background border-2 border-foreground px-6 py-3 text-sm tracking-wider hover:opacity-80 transition-colors"
            >
              → SUBMIT
            </button>
          </div>
        </form>
      </div>
    </Layout>
  );
};

export default Form;