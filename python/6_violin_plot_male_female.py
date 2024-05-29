import pandas as pd
import matplotlib.pyplot as plt
import json
import seaborn as sns
sns.set_palette("hls")

if __name__ == '__main__':
    # Load the csv into dataframe
    ltr_df = pd.read_csv("../data/sex-specific-ltr.csv")
    ltr_list = ltr_df["ltr"].tolist()
    count = ltr_df.shape[0]
    # convert ltr_df to dictionnary
    sex_specificity = ltr_df.set_index("ltr").to_dict()['sex-specificity']

    # Make a subplot, 6 rows and 4 columns
    fig, axes = plt.subplots(6, 4, figsize=(25, 25))
    for i, ax in enumerate(axes.ravel()):
        if i >= count:
            ax.set_visible(False)
            continue
        # Plot the violin plot
        ltr = ltr_list[i]
        ltr_sex = sex_specificity[ltr]
        # Load series
        data = json.loads(open(f"../data/validate_ltr_v2/json_series/{ltr}.json").read())
        # Make the violin plot
        df = [{
            "val": a,
            "sex": ltr_sex
        } for a in data["same-sex"]]
        df = df + [{
            "val": a,
            "sex": 'male' if ltr_sex == 'female' else 'female'
        } for a in data["opposite-sex"]]
        df = pd.DataFrame(df)
        df["sex-i"] = df["sex"].apply(lambda x: 0 if x == ltr_sex else 1)

        plt.figure(figsize=(10,6))
        sns.violinplot(df, x='sex', y='val', ax=ax, hue='sex')
        # sns.boxplot(data=df, x='sex', y='val', ax=ax, hue='sex')
        # sns.scatterplot(data=df, x='sex', y='val', ax=ax, hue='sex')
        ax.set_title(ltr)

        # Remove xlabel
        ax.set_xlabel('')
        ax.set_ylabel('ratio')

    # Save the plot
    plt.show()
    #plt.savefig(f"../data/violin-plot-ltr.png")
    print()